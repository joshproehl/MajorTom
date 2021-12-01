#!/usr/bin/env bash
# Based on https://gist.github.com/bobmaerten/9329752

CONTAINER_NAME="majortom-dev-postgres"
CONTAINER_PORT="57433"
CONTAINER_PG_PASSWORD="majortomdeveloper"
DEV_DATABASE_NAME="major_tom_dev"

function getContainerStatus(){
  CONTAINER_ID=$(docker ps -a | grep -v Exit | grep $CONTAINER_NAME | awk '{print $1}')
  if [[ -z $CONTAINER_ID ]] ; then
    echo "Not running."
    return 1
  else
    echo "$CONTAINER_NAME ($CONTAINER_ID) running on $CONTAINER_PORT"
    return 0
  fi
}

case "$1" in
  start)
    docker ps -a | grep -v Exit | grep -q $CONTAINER_NAME
    if [ $? -ne 0 ]; then
      docker run --rm -p $CONTAINER_PORT:5432 -v "/tmp/$CONTAINER_NAME-data:/var/lib/postgresql/data" -e POSTGRES_PASSWORD=$CONTAINER_PG_PASSWORD --name $CONTAINER_NAME -d postgres:13
    fi
    getContainerStatus
    ;;
  stop)
    CONTAINER_ID=$(docker ps -a | grep -v Exit | grep $CONTAINER_NAME | awk '{print $1}')
    if [[ -n $CONTAINER_ID ]] ; then
      SRV=$(docker stop $CONTAINER_ID)
      if [ $? -eq 0 ] ; then
        echo 'Stopped.'
      fi
    fi
    ;;
  dev-console)
    docker exec -it $CONTAINER_NAME psql -U postgres $DEV_DATABASE_NAME
    ;;
  *)
    printf "Usage: `basename $0` {start|stop|dev-console} \nStarts (or stops and deletes) a postegres docker container named $CONTAINER_NAME on port $CONTAINER_PORT, which the dev environment is expecting to find.\nAlso provides a convenient way to access a psql console.\n\n"
    exit 1
    ;;
esac

exit 0
