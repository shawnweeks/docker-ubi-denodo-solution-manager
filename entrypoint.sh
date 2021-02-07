#!/bin/bash

set -e
umask 0027

monitor() {
    while true
    do   
        sleep 30
        PS_OUTPUT=$(ps ux)
        if [[ "$PS_OUTPUT" != *'Denodo Platform License Manager 7.0'* ]]; then
            echo "License Manager Not Running - Exiting Now"
            shutdown 1
        elif [[ "$PS_OUTPUT" != *'Denodo VDP Server 7.0'* ]]; then
            echo "VQL Server not Running - Exiting Now"
            shutdown 1
        elif [[ "$PS_OUTPUT" != *'Denodo Platform Solution Manager 7.0'* ]]; then  
            echo "Solution Manager Not Runnig - Exiting Now"
            shutdown 1
        elif [[ "$PS_OUTPUT" != *'apache-tomcat'* ]]; then  
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
    tail -n +1 -F \
        $HOME/logs/solution-manager/solution-manager.log \
        $HOME/logs/license-manager/license-manager.log \
        $HOME/logs/vdp/vdp.log \
        $HOME/logs/vdp/vdp-cache.log \
        $HOME/logs/vdp/vdp-queries.log \
        $HOME/logs/vdp/vdp-requests.log \
        $HOME/logs/apache-tomcat/tomcat.log \
        $HOME/logs/apache-tomcat/denodows.log &
    TAIL_PID="$!"    
    monitor
}

shutdown() {
    echo Stopping Solution Manager Web Tool
    ${HOME}/bin/solutionmanagerwebtool_shutdown.sh
    echo Stopping Solution Manager
    ${HOME}/bin/solutionmanager_shutdown.sh
    echo Stopping VQL Server
    ${HOME}/bin/vqlserver_shutdown.sh
    echo Stopping License Manager
    ${HOME}/bin/licensemanager_shutdown.sh
    echo Stopping Logging
    kill -sigterm $TAIL_PID
    exit ${1:-0}    
}

entrypoint.py

${HOME}/bin/regenerateFiles.sh

trap "shutdown" INT TERM

unset "${!DENODO_@}"

startup