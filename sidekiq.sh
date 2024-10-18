#!/bin/sh

ACTION=$1
RETRY_LIMIT=3
RETRY_WAIT=5

start_function(){
  bundle exec sidekiq -C config/sidekiq.yml
}

stop_function(){
  # SIGTERM triggers a quick exit; gracefully terminate instead.
  # Find PID
  SIDEKIQ_PID=$(ps aux | grep sidekiq | grep busy | awk '{ print $2 }')

  if [ -z "$SIDEKIQ_PID" ]; then
    echo "No Sidekiq PIDs found."
  else
    echo "Sending TSTP signal..."
    kill -TSTP ${SIDEKIQ_PID}

    # Wait until it finishes all the jobs and then send a TERM signal to it
    wait_function

    echo "Sending TERM signal..."
    kill -TERM ${SIDEKIQ_PID}
  fi
}

wait_function(){
  sleep 2

  i=0
  while [ ${i} -lt ${RETRY_LIMIT} ]; do
    i=$((i+1))

    IS_SIDEKIQ_DONE=$(sidekiqmon processes | grep -q "(0 busy)"; echo $?)

    if [ ${IS_SIDEKIQ_DONE} -eq 0 ]; then
      echo "Sidekiq finished all jobs."
      break
    else
      echo "Sidekiq is still busy. Retry $i/$RETRY_LIMIT Waiting $RETRY_WAIT seconds..."
      sleep ${RETRY_WAIT}
    fi
  done
}

# This is used in the kubernetes deployment readinessProbe and livenessProbe.
probe_function(){
  MONITOR_OUTPUT=$(sidekiqmon processes) || exit 1

  # Check redis connection
  REDIS_CHECK=$(echo ${MONITOR_OUTPUT} | grep -q "ECONNREFUSED"; echo $?)

  # Check there is at least 1 process running
  PROCESSES_CHECK=$(echo ${MONITOR_OUTPUT} | grep -q "Processes (0)"; echo $?)

  # Check there is more than 1 thread running (normally will be 3)
  THREADS_CHECK=$(echo ${MONITOR_OUTPUT} | grep -qE "Threads: \b[0-1]\b"; echo $?)

  # If any of the above checks returns '0' it means the regex found a match
  if [ ${REDIS_CHECK} -eq 0 ] || [ ${PROCESSES_CHECK} -eq 0 ] || [ ${THREADS_CHECK} -eq 0 ]; then
    echo 'Sidekiq probe: KO'
    exit 1
  fi

  echo 'Sidekiq probe: OK'
}

if [ -z "$REDIS_URL" ]; then
  echo 'REDIS_URL env variable not set. Defaulting to redis://localhost:6379'
fi

case "$ACTION" in
  start)
    start_function
    ;;
  stop)
    stop_function
    ;;
  restart)
    stop_function && start_function
    ;;
  probe)
    probe_function
    ;;
  *)
  echo "Usage: $0 [start|stop|restart|probe]"
esac
