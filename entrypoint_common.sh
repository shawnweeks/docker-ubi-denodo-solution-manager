# Replaces or Appends Key Value Pairs in a Java Style Properties File
prop_replace() {
    local KEY=$1
    local VALUE=$2
    local FILE=$3

    if ! grep --silent "^[#]*\s*${KEY}=.*" ${FILE} 2>/dev/null; then
        echo "APPENDING '${VALUE}' because '${KEY}' not found in ${FILE}."
        echo "${KEY}=${VALUE}" >> ${FILE}
    elif ! grep --silent "^${KEY}=${VALUE}" ${FILE} 2>/dev/null; then
        echo "UPDATING '${VALUE}' because '${KEY}' was different in ${FILE}."
        sed -i.backup "s~^[#]*\s*${KEY}=.*~${KEY}=${VALUE}~" ${FILE}
    else
        echo "SKIPPING '${KEY}' because '${VALUE}' already set in ${FILE}."
    fi
}

startup() {    
    echo Starting License Manager
    ${HOME}/bin/licensemanager_startup.sh
    echo Starting VQL Server    
    ${HOME}/bin/vqlserver_startup.sh
    echo Starting Solution Manager    
    ${HOME}/bin/solutionmanager_startup.sh
    echo Starting Solution Manager Web Tool
    ${HOME}/bin/solutionmanagerwebtool_startup.sh  
    if [[ "${START_DESIGN_STUDIO,,}" == 'true' ]]; then
        echo Starting Design Studio
        ${HOME}/bin/designstudio_startup.sh
    fi
    if [[ "${START_SCHEDULER_WEB_ADMIN,,}" == 'true' ]]; then
        echo Starting Scheduler Web Admin
        ${HOME}/bin/scheduler_webadmin_startup.sh
    fi
    if [[ "${START_DIAGNOSTIC_AND_MONITORING,,}" == 'true' ]]; then
        echo Starting Diagnostic and Monitoring
        ${HOME}/bin/diagnosticmonitoringtool_startup.sh
    fi
    monitor
}

monitor() {
    while true
    do   
        sleep 30
        PS_OUTPUT=$(ps ux)
        if [[ "$PS_OUTPUT" != *'Denodo Platform License Manager 8.0'* ]]; then
            echo "License Manager Not Running - Exiting Now"
            shutdown 1
        elif [[ "$PS_OUTPUT" != *'Denodo VDP Server 8.0'* ]]; then
            echo "VQL Server not Running - Exiting Now"
            shutdown 1
        elif [[ "$PS_OUTPUT" != *'Denodo Platform Solution Manager 8.0'* ]]; then  
            echo "Solution Manager Not Runnig - Exiting Now"
            shutdown 1
        elif [[ "$PS_OUTPUT" != *'Denodo Web Container 8.0'* ]]; then  
            echo "Web Container Not Running - Exiting Now"
            shutdown 1          
        fi
    done
}

shutdown() {    
    # if [[ "${START_DIAGNOSTIC_AND_MONITORING,,}" == 'true' ]]; then
    #     echo Stopping Diagnostic and Monitoring
    #     ${HOME}/bin/diagnosticmonitoringtool_shutdown.sh
    # fi
    # if [[ "${START_SCHEDULER_WEB_ADMIN,,}" == 'true' ]]; then
    #     echo Stopping Scheduler Web Admin
    #     ${HOME}/bin/scheduler_webadmin_shutdown.sh
    # fi
    # if [[ "${START_DESIGN_STUDIO,,}" == 'true' ]]; then
    #     echo Stopping Design Studio
    #     ${HOME}/bin/designstudio_shutdown.sh
    # fi
    # echo Stopping Solution Manager Web Tool    
    
    # During shutdown we can just shutdown Tomcat 
    # instead of shutting each item down directly.
    echo Stopping Web Container
    ${HOME}/bin/webcontainer_shutdown.sh
    echo Stopping Solution Manager
    ${HOME}/bin/solutionmanager_shutdown.sh
    echo Stopping VQL Server
    ${HOME}/bin/vqlserver_shutdown.sh
    echo Stopping License Manager
    ${HOME}/bin/licensemanager_shutdown.sh

    exit ${1:-0}    
}

configure_external_db() {
    if ! [[ "${DENODO_USE_EXTERNAL_DB,,}" == 'true' ]]
    then
        return 0
    fi
    
    echo "Enabling External Metadata Database"
    ${HOME}/bin/regenerateMetadata.sh \
        --adapter "${DENODO_STORAGE_PLUGIN}" \
        --version "${DENODO_STORAGE_VERSION}" \
        --driver "${DENODO_STORAGE_DRIVER}" \
        ${DENODO_STORAGE_DRIVER_PROPERTIES:+--driverProperties} "${DENODO_STORAGE_DRIVER_PROPERTIES}" \
        --classPath "${DENODO_STORAGE_CLASSPATH}" \
        --databaseUri "${DENODO_STORAGE_URI}" \
        --user "${DENODO_STORAGE_USER}" \
        --password "${DENODO_STORAGE_PASSWORD}" \
        ${DENODO_STORAGE_CATALOG:+--catalog} "${DENODO_STORAGE_CATALOG}" \
        ${DENODO_STORAGE_CATALOG:+--schema} "${DENODO_STORAGE_SCHEMA}" \
        --initialSize  "${DENODO_STORAGE_INITIAL_SIZE:-4}" \
        --maxActive "${DENODO_STORAGE_INITIAL_SIZE:-100}" \
        --testConnections \
        --pingQuery "${DENODO_STORAGE_PING_QUERY:-select 1}" \
        --yes
    }

configure_ssl() {
    if ! [[ "${DENODO_SSL_ENABLED,,}" == 'true' ]]
    then
        return 0
    fi

    echo "Enabling SSL"

    # Populating Credentials file with Keystore and Truststore Password
    #echo "keystore.password=$(${HOME}/bin/encrypt_password.sh ${DENODO_SSL_KEYSTORE_PASSWORD} | grep -v 'Encrypted Password:' )" > ${HOME}/conf/credentials
    #echo "truststore.password=$(${HOME}/bin/encrypt_password.sh ${DENODO_SSL_TRUSTSTORE_PASSWORD} | grep -v 'Encrypted Password:')" >> ${HOME}/conf/credentials

    prop_replace "keystore.password" "$(${HOME}/bin/encrypt_password.sh ${DENODO_SSL_KEYSTORE_PASSWORD} | grep -v 'Encrypted Password:' )" "${HOME}/conf/credentials"
    prop_replace "truststore.password" "$(${HOME}/bin/encrypt_password.sh ${DENODO_SSL_TRUSTSTORE_PASSWORD} | grep -v 'Encrypted Password:' )" "${HOME}/conf/credentials"
    
    # Making local copies so we don't have to modify the external files
    cp ${DENODO_SSL_KEYSTORE} ${HOME}/conf/keystore.jks
    cp ${DENODO_SSL_TRUSTSTORE} ${HOME}/conf/truststore.jks

    # Because Denodo made some poor descisions we need to extract the cert just to put it back
    keytool -exportcert -keystore ${DENODO_SSL_KEYSTORE} -storepass ${DENODO_SSL_KEYSTORE_PASSWORD} -alias ${DENODO_SSL_KEYSTORE_ALIAS} -file ${HOME}/conf/cert.cer 2>/dev/null

    # Running Denodo SSL Configuration Script
    ${HOME}/bin/denodo_tls_configurator.sh \
        --denodo-home ${HOME} \
        --keystore ${HOME}/conf/keystore.jks \
        --truststore ${HOME}/conf/truststore.jks \
        --cert-cer-file ${HOME}/conf/cert.cer \
        --credentials-file ${HOME}/conf/credentials \
        --license-manager-uses-tls=true
    
    # Cleanup Files    
    rm ${HOME}/conf/cert.cer ${HOME}/conf/credentials
}

# This breaks log4j2 so I'll have to wait for a fix from Denodo
# fix_java_11() {
#     for FILE in $(grep -P '^DENODO_JRE11_OPTIONS' ${HOME}/bin/*.sh -l)
#     do
#         : ${DENODO_JRE11_OPTIONS:=-Xshare:off -Djava.locale.providers=COMPAT,SP}
#         echo "Setting DENODO_JRE11_OPTIONS to \"${DENODO_JRE11_OPTIONS}\" in ${FILE}"
#         sed -i -r "s/(DENODO_JRE11_OPTIONS=).*/\1\"${DENODO_JRE11_OPTIONS}\"/" "${FILE}"
#     done
# }

configure_rmi_hostname() {
    prop_replace \
        "com.denodo.vdb.vdbinterface.server.VDBManagerImpl.registryURL" \
        "${DENODO_RMI_HOSTNAME:-localhost}" \
        ${HOME}/conf/vdp/VDBConfiguration.properties

    prop_replace \
        "com.denodo.solutionmanager.rmi.host" \
        "${DENODO_RMI_HOSTNAME:-localhost}" \
        ${HOME}/conf/solution-manager/SMConfigurationParameters.properties

    prop_replace \
        "com.denodo.licensemanager.rmi.host" \
        "${DENODO_RMI_HOSTNAME:-localhost}" \
        ${HOME}/conf/license-manager/LMConfigurationParameters.properties

    prop_replace \
        "com.denodo.tomcat.jmx.rmi.host" \
        "${DENODO_RMI_HOSTNAME:-localhost}" \
        ${HOME}/resources/apache-tomcat/conf/tomcat.properties
}

configure_java_opts() {
    prop_replace \
        "java.env.DENODO_OPTS_START" \
        "${DENODO_VDP_JAVA_OPTS:--Xmx1024m -XX:NewRatio=4}" \
        ${HOME}/conf/vdp/VDBConfiguration.properties

    prop_replace \
        "java.env.DENODO_OPTS_START" \
        "${DENODO_SM_JAVA_OPTS:--Xmx1024m}" \
        ${HOME}/conf/solution-manager/SMConfigurationParameters.properties

    prop_replace \
        "java.env.DENODO_OPTS_START" \
        "${DENODO_LM_JAVA_OPTS:--Xmx1024m}" \
        ${HOME}/conf/license-manager/LMConfigurationParameters.properties

    prop_replace \
        "java.env.DENODO_OPTS_START" \
        "${DENODO_WEB_JAVA_OPTS:--Xmx1024m -Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=true -Dorg.apache.catalina.connector.CoyoteAdapter.ALLOW_BACKSLASH=true -Djava.locale.providers=COMPAT,SPI}" \
        ${HOME}/resources/apache-tomcat/conf/tomcat.properties
}

configure_sso() {
    if ! [[ "${DENODO_SSO_ENABLED}" == 'true' ]]
    then
        return 0
    fi

    prop_replace \
        "sso.url" \
        "${DENODO_SSO_URL}" \
        ${HOME}/conf/SSOConfiguration.properties
    
    prop_replace \
        "sso.token-enabled" \
        "true" \
        ${HOME}/conf/SSOConfiguration.properties
    
    prop_replace \
        "sso.enabled" \
        "true" \
        ${HOME}/conf/SSOConfiguration.properties                

    prop_replace \
        "authorization.token.enabled" \
        "true" \
        ${HOME}/conf/denodo-sso/SSOTokenConfiguration.properties
    
    prop_replace \
        "authorization.token.signing.auto-generated" \
        "true" \
        ${HOME}/conf/denodo-sso/SSOTokenConfiguration.properties

    prop_replace \
        "authorization.type" \
        "${DENODO_SSO_TYPE}" \
        ${HOME}/conf/denodo-sso/SSOTokenConfiguration.properties
    
    if [[ "${DENODO_SSO_TYPE}" == 'saml' ]]
    then
        FILE=${HOME}/conf/denodo-sso/SSOTokenConfiguration.properties
        prop_replace "saml.enabled" "true" ${FILE}
        prop_replace "saml.use-general-signing" "${DENODO_SSO_SAML_SIGN_REQ}" ${FILE}
        prop_replace "saml.sp-entityid" "${DENODO_SSO_SAML_ENTITY_ID}" ${FILE}
        if [[ -n ${DENODO_SSO_SAML_METADATA_URL} ]]
        then
            prop_replace "saml.idp-metadata-url" "${DENODO_SSO_SAML_METADATA_URL}" ${FILE}
        else
            prop_replace "saml.idp-metadata-file" "${DENODO_SSO_SAML_METADATA_FILE}" ${FILE}        
        fi
        prop_replace "saml.extract-role.delegate" "${DENODO_SSO_SAML_EXTRACT_ROLE_DELEGATE}" ${FILE}
        prop_replace "saml.extract-role.field" "${DENODO_SSO_SAML_EXTRACT_ROLE_FIELD}" ${FILE}
    fi
}

configure() {
    START_DESIGN_STUDIO="${DENODO_START_DESIGN_STUDIO:-false}"
    START_SCHEDULER_WEB_ADMIN="${DENODO_START_SCHEDULER_WEB_ADMIN:-false}"
    START_DIAGNOSTIC_AND_MONITORING="${DENODO_START_DIAGNOSTIC_AND_MONITORING:-false}"

    echo "${DENODO_LICENSE}" > /opt/denodo/conf/denodo.lic
    
    entrypoint.py

    # This breaks log4j2 so I'll have to wait for a fix from Denodo
    # fix_java_11

    configure_rmi_hostname
    
    configure_java_opts

    configure_ssl

    configure_external_db

    ${HOME}/bin/regenerateFiles.sh
}