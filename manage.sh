#!/bin/bash

set -e

PROJECT="$(cat .project-name)"
PROJECT_HOME="$( cd "$( dirname "$0" )" && pwd )"
INFRAESTRUCTURA_HOME="${PROJECT_HOME}/infraestructura"

cd $INFRAESTRUCTURA_HOME

case "$1" in
    start)
        docker-compose --project-name ${PROJECT} up -d reverseproxy api db rabbitmq redis
        ;;
    stop)
        docker-compose  --project-name ${PROJECT} stop
        ;;
    build)
        docker-compose  --project-name ${PROJECT} build
        ;;
    rebuild)
        docker-compose  --project-name ${PROJECT} build --no-cache
        ;;
    logs)
        docker-compose --project-name ${PROJECT} logs -f -t
        ;;
    status)
        docker-compose --project-name ${PROJECT} ps
        ;;
    run)
        if [ "$#" -lt  "2" ]
        then
            echo $"Usage: $0 $1 <command>"
            RETVAL=1
        else
            shift
            docker-compose  --project-name ${PROJECT} run bastion "$@"
        fi
        ;;
    bastion)
        docker-compose  --project-name ${PROJECT} run bastion
        ;;
    *)
        echo $"Usage: $0 {start|stop|build|rebuild|run|logs|status}"
        RETVAL=1
esac

cd - > /dev/null
