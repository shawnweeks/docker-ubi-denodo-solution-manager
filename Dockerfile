ARG BASE_REGISTRY
ARG BASE_IMAGE=redhat/ubi/ubi8
ARG BASE_TAG=8.3

FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG} as build

ARG DENODO_VERSION
ARG DENODO_PACKAGE=denodo-install-solutionmanager-8.0-ga-linux64.zip
ARG DENODO_UPDATE_PACKAGE=denodo-solutionmanager-v80-update-${DENODO_VERSION}.zip

COPY [ "${DENODO_PACKAGE}", "${DENODO_UPDATE_PACKAGE}", "denodo_response_8.xml", "/tmp/" ]

RUN yum install -y unzip java-11-openjdk-devel && \
    unzip /tmp/${DENODO_PACKAGE} -d /tmp/ && \
    mkdir -p /tmp/denodo-install-solutionmanager-8.0/denodo-update/ && \
    unzip /tmp/${DENODO_UPDATE_PACKAGE} -d /tmp && \
    mv /tmp/denodo-solutionmanager-v80-update-*.jar /tmp/denodo-install-solutionmanager-8.0/denodo-update/denodo-update.jar && \
    sh /tmp/denodo-install-solutionmanager-8.0/installer_cli.sh install --autoinstaller /tmp/denodo_response_8.xml && \
    cp /opt/denodo/lib/extensions/jdbc-drivers/postgresql-12/postgresql-42.2.5.jar /opt/denodo/lib/solution-manager-extensions/ && \
    mkdir /opt/denodo/conf_original && \
    mv /opt/denodo/conf/* /opt/denodo/conf_original/ && \
    rm -rf /opt/denodo/jre /opt/denodo/logs/*/*.log
    
###############################################################################
FROM ${BASE_REGISTRY}/${BASE_IMAGE}:${BASE_TAG}

ENV DENODO_USER=denodo
ENV DENODO_GROUP=denodo
ENV DENODO_UID=2001
ENV DENODO_GID=2001

ENV DENODO_HOME=/opt/denodo

RUN yum install -y java-11-openjdk-devel procps git && \
    yum clean all && \    
    mkdir -p ${DENODO_HOME} && \
    groupadd -r -g ${DENODO_GID} ${DENODO_GROUP} && \
    useradd -r -u ${DENODO_UID} -g ${DENODO_GROUP} -M -d ${DENODO_HOME} ${DENODO_USER} && \
    chown ${DENODO_USER}:${DENODO_GROUP} ${DENODO_HOME} -R

COPY --from=build --chown=${DENODO_USER}:${DENODO_GROUP} [ "${DENODO_HOME}/", "${DENODO_HOME}/" ]
COPY --chown=${DENODO_USER}:${DENODO_GROUP} [ "entrypoint*", "${DENODO_HOME}/" ]

COPY [ "templates/*.j2", "/opt/jinja-templates/" ]

RUN chmod 755 ${DENODO_HOME}/entrypoint.*

EXPOSE 10090 10091 19090 19443 19999

VOLUME /opt/denodo/metadata
VOLUME /opt/denodo/conf

USER ${DENODO_USER}
ENV JAVA_HOME=/usr/lib/jvm/java-11
ENV PATH=${PATH}:${DENODO_HOME}
WORKDIR ${DENODO_HOME}
ENTRYPOINT [ "entrypoint.sh" ]