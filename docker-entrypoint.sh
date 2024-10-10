#!/bin/bash

POST_START_DIR=/docker-entrypoint.d/post-start
PRE_STOP_DIR=/docker-entrypoint.d/pre-stop

if [[ -d "$POST_START_DIR" ]]; then
  /bin/run-parts --verbose "$POST_START_DIR"
fi


function gracefulshutdown {
  echo "stop process :: "$PID
  if [[ -d "$PRE_STOP_DIR" ]]; then
    /bin/run-parts --verbose "$PRE_STOP_DIR"
  fi
  kill -15 "$PID" && echo "Shutting down!"
}

trap gracefulshutdown SIGTERM
trap gracefulshutdown SIGINT

echo "start process..."

ARG_ARR=($@)

cnt=0
for arg in ${ARG_ARR[@]} ; do
	if [[ "$arg" =~ .*\>$ ]]; then
		idx=$(($cnt+1))
		LOG_DIR=${ARG_ARR[$idx]%/*.*}
		LOG_DIR=${LOG_DIR/\$\{HOSTNAME\}/`echo ${HOSTNAME}`}
		LOG_DIR=${LOG_DIR/\$\{SPRING_PROFILES_ACTIVE\}/`echo ${SPRING_PROFILES_ACTIVE}`}
		echo $LOG_DIR
		mkdir -p ${LOG_DIR}
		eval "exec $arg ${ARG_ARR[$idx]}"
	fi
	((cnt++))
done



exec "$@" &
PID="$!"

wait $PID
