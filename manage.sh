#!/bin/bash

set -e

PROJECT="$(cat .project-name)"
PROJECT_HOME="$( cd "$( dirname "$0" )" && pwd )"
INFRASTRUCTURE_HOME="${PROJECT_HOME}/infrastructure"

cd $INFRASTRUCTURE_HOME

case "$1" in
    start)
        docker-compose --project-name ${PROJECT} up -d food_db #triage #tyra reverseproxy api
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
    destroy)
        docker-compose  --project-name ${PROJECT} down --rmi all --remove-orphans --volumes
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
            docker-compose  --project-name ${PROJECT} run --rm --name tutorial_bastion bastion "$@"
        fi
        ;;
    bastion)
        docker-compose  --project-name ${PROJECT} run --rm --name tutorial_bastion bastion
        ;;
    *)
        echo $"Usage: $0 {start|stop|build|rebuild|run|logs|status|destroy}"
        RETVAL=1
esac

cd - > /dev/null
