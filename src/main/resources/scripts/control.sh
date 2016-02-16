#!/bin/bash -x

date -u +"20%y-%m-%d %H:%M:%S" 1>&2

THIS_SCRIPT=$0
PROCESS_DIR=$(pwd)
# PROCESS_DIR=$(dirname ${THIS_SCRIPT})
CMD=$1
shift 1

function log {
  TIMESTAMP=$(date -u +"20%y-%m-%d %H:%M:%S")
  echo "${TIMESTAMP} - $1"
  echo "${TIMESTAMP} - $1" 1>&2
}

function setVariable {
  KEY=$1
  VALUE=$2
  DEFAULT_VALUE=$3

  if [ -z "${!KEY}" ]
  then
    if [ -z "${VALUE}" ]
    then
      VALUE="${DEFAULT_VALUE}"
    fi

    log "Exporting ${KEY}=${VALUE}"
    export ${KEY}="${VALUE}"
  fi
}

function readConfLine {
  IFS="=" read key value <<< "$1"
}

function parseConf {
  for line in $(cat ${PROCESS_DIR}/drill-conf/drill-cloudera.conf)
  do
    readConfLine $line
    case $key in
      cluster.id)
        unset DRILL_CLUSTER_ID
        setVariable DRILL_CLUSTER_ID "$value" "drill1"
        ;;

      zk.connect)
        unset ZK_CONNECT
        setVariable ZK_CONNECT "$value" "${ZK_QUORUM}"
        ;;

      drill.max.direct.memory)
        unset DRILL_MAX_DIRECT_MEMORY
        setVariable DRILL_MAX_DIRECT_MEMORY "$value" "8G"
        ;;

      drill.heap)
        unset DRILL_HEAP
        setVariable DRILL_HEAP "$value" "4G"
        ;;
   
      drill.log.dir)
        unset DRILL_LOG_DIR
        setVariable DRILL_LOG_DIR "$value" "/var/log/drill"
        ;;

      *)
        log "Unknown property ${key} with value ${value}"
        ;;
    esac
  done
}

log "Got command: ${CMD}"

DRILL_CONTROL_SH_DEBUG=1
if [ "${DRILL_CONTROL_SH_DEBUG}" = "1" ]
then
    env | sort 1>&2
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
        
        . ${DRILL_HOME}/bin/drill-config.sh

        parseConf

        cat ${PROCESS_DIR}/aux/drill-override.conf | envsubst >| ${DRILL_CONF_DIR}/drill-override.conf
        log "New configuration file: "
        cat ${DRILL_CONF_DIR}/drill-override.conf
        exit 0 
        ;;

    Client)
	log "Client. Nothing to do."
	exit 0
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
