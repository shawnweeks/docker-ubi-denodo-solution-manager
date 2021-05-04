#!/bin/bash

set -e
umask 0027

: ${DENODO_START_DESIGN_STUDIO:=true}
: ${DENODO_START_SCHEDULER_WEB_ADMIN:=true}
: ${DENODO_START_DIAGNOSTIC_AND_MONITORING:=true}
: ${DENODO_EXT_META_DB_PROP_FILE:=${DENODO_HOME}/conf/metadb.properties}
: ${DENODO_USE_EXTERNAL_METADATA:=false}

START_DESIGN_STUDIO="$DENODO_START_DESIGN_STUDIO"
START_SCHEDULER_WEB_ADMIN="$DENODO_START_SCHEDULER_WEB_ADMIN"
START_DIAGNOSTIC_AND_MONITORING="$DENODO_START_DIAGNOSTIC_AND_MONITORING"

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

shutdown() {
    if [[ "${START_DIAGNOSTIC_AND_MONITORING,,}" == 'true' ]]; then
        echo Stopping Diagnostic and Monitoring
        ${HOME}/bin/diagnosticmonitoringtool_shutdown.sh
    fi
    if [[ "${START_SCHEDULER_WEB_ADMIN,,}" == 'true' ]]; then
        echo Stopping Scheduler Web Admin
        ${HOME}/bin/scheduler_webadmin_shutdown.sh
    fi
    if [[ "${START_DESIGN_STUDIO,,}" == 'true' ]]; then
        echo Stopping Design Studio
        ${HOME}/bin/designstudio_shutdown.sh
    fi
    echo Stopping Solution Manager Web Tool
    ${HOME}/bin/solutionmanagerwebtool_shutdown.sh
    echo Stopping Solution Manager
    ${HOME}/bin/solutionmanager_shutdown.sh
    echo Stopping Design Studio
    ${HOME}/bin/designstudio_shutdown.sh
    echo Stopping Scheduler Web Admin
    ${HOME}/bin/scheduler_webadmin_shutdown.sh
    echo Stopping VQL Server
    ${HOME}/bin/vqlserver_shutdown.sh
    echo Stopping License Manager
    ${HOME}/bin/licensemanager_shutdown.sh

    exit ${1:-0}    
}

if [[ "${DENODO_USE_EXTERNAL_METADATA,,}" == 'true' && -n "$DENODO_STORAGE_PASSWORD" ]]; then
    export DENODO_STORAGE_ENCRYPTEDPASSWORD="$(${HOME}/bin/encrypt_password.sh $DENODO_STORAGE_PASSWORD | grep 'Encrypted Password:' -v)"
fi

printf "%s" "$DENODO_LICENSE" > /opt/denodo/license/denodo.lic

entrypoint.py

${HOME}/bin/regenerateFiles.sh

if [[ "${DENODO_USE_EXTERNAL_METADATA,,}" == 'true' ]]; then
    echo Regenerating metadata from database
    if [[ -f "${DENODO_EXT_META_DB_PROP_FILE}" ]]; then
        ${HOME}/bin/regenerateMetadata.sh --file ${DENODO_EXT_META_DB_PROP_FILE} -y
    else
        echo "External metadata database properties file '${DENODO_EXT_META_DB_PROP_FILE}' not found"
        exit 1
    fi
fi

trap "shutdown" INT TERM

unset "${!DENODO_@}"

startup