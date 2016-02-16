#!/bin/bash -x

date -u +"20%y-%m-%d %H:%M:%S" 1>&2

CMD=$1
shift 1

function log {
  TIMESTAMP=$(date -u +"20%y-%m-%d %H:%M:%S")
  echo "${TIMESTAMP} - $1"
  echo "${TIMESTAMP} - $1" 1>&2
}

log "Got command: ${CMD}"

DRILL_CONTROL_SH_DEBUG=1
if [ "${DRILL_CONTROL_SH_DEBUG}" = "1" ]
then
    env | sort
    pwd
fi

case "${CMD}" in

    Start)
        log "Starting Drillbit"
        DRILL_CMD="internal_start"
        ;;
        
    Stop)
        log "Stopping Drillbit"
        DRILL_CMD="stop"
        ;;
        
    Restart)
        log "Restarting Drillbit"
        DRILL_CMD="restart"
        ;;
    
    Status)
        log "Getting status"
        DRILL_CMD="status"
        ;;
    
    Autorestart)
        log "Setting autorestart"
        DRILL_CMD="autorestart"
        ;;
        
    Deploy)
        log "Deploying drillbit configuration"
        DRILL_CMD=""
        if [ -z "${DRILL_CLUSTER_ID}" ]
        then
            export DRILL_CLUSTER_ID=drill1
        fi
        if [ -z "${ZK_CONNECT}" ]
        then
            export ZK_CONNECT=${ZK_QUORUM}
        fi
        cat 
        ;;
        
    *)
        log "Unknown command: ${CMD}"
        exit 1
        ;;
esac

export HADOOP_HOME=${CDH_HADOOP_HOME}
export HBASE_HOME=${CDH_HBASE_HOME}

if [ ! -z "${DRILL_CMD}" ]
then
  . ${DRILL_HOME}/bin/drillbit_cdh.sh ${DRILL_CMD}
fi

