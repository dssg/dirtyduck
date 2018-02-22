#!/bin/bash

set -e -u

PROJECT="$(cat .project-name)"
PROJECT_HOME="$( cd "$( dirname "$0" )" && pwd )"
INFRASTRUCTURE_HOME="${PROJECT_HOME}/infrastructure"

cd $INFRASTRUCTURE_HOME

function help_menu () {
cat << EOF
Usage: ${0} {start|stop|build|rebuild|run|logs|status|destroy|all|}

OPTIONS:
   -h|help             Show this message
   start
   stop
   rebuild
   status
   destroy
   -t|triage
   -a|all

INFRASTRUCTURE:
   All the infrastructure needed is turned on!
        $ ./tutorial.sh start

   Check the status of the containers:
        $ ./tutorial.sh status

   Stop the tutorial's infrastructure:
        $ ./tutorial.sh stop

   Destroy all the resources related to the tutorial:
        $ ./tutorial.sh destroy

   Infrastructure logs:
        $ ./tutorial.sh -l

EXPERIMENTS:
   NOTE:
      The following commands assume that "sample_experiment_config.yaml"
      is located inside triage/experiment_config  directory

   Run one experiment:
        $ ./tutorial.sh -t --config_file sample_experiment_config.yaml run

   Run one experiment, without replacing matrices or models if already exist and with debug enabled:
        $ ./tutorial.sh -t --config_file sample_experiment_config.yaml --no-replace --debug run

   Validate experiment configuration file:
        $ ./tutorial.sh triage --config_file sample_experiment_config.yaml validate

   Show experiment's temporal cross-validation blocks:
        $ ./tutorial.sh -t --config_file sample_experiment_config.yaml show_temporal_blocks

   Plot the model number 4 (if it is a Decision Tree or a Random Forest):
        $ ./tutorial.sh -t --config_file sample_experiment_config.yaml show_model_plot --model 4

   Triage help:
        $ ./tutorial.sh triage --help

EOF
}

function start_infrastructure () {
    docker-compose --project-name ${PROJECT} up -d food_db
	#tyra reverseproxy api
}

function stop_infrastructure () {
	docker-compose  --project-name ${PROJECT} stop
}

function build_images () {
	docker-compose  --project-name ${PROJECT} build "${@}"
}

function destroy () {
	docker-compose  --project-name ${PROJECT} down --rmi all --remove-orphans --volumes
}

function infrastructure_logs () {
    docker-compose --project-name ${PROJECT} logs -f -t
}

function status () {
	docker-compose --project-name ${PROJECT} ps
}

function bastion () {
    docker-compose --project-name ${PROJECT} run --rm --name tutorial_bastion bastion
}

function triage () {
	docker-compose  --project-name ${PROJECT} run --rm --name triage_experiment triage "${@}"
}

function all () {
	build_images
	start_infrastructure
	status
}


if [[ $# -eq 0 ]] ; then
	help_menu
	exit 0
fi

case "$1" in
    start)
        start_infrastructure
		shift
        ;;
    stop)
        stop_infrastructure
		shift
        ;;
    build)
        build_images
		shift
        ;;
    rebuild)
        build_images --no-cache
		shift
        ;;
    -d|destroy)
        destroy
		shift
        ;;
    -l|logs)
        infrastructure_logs
		shift
        ;;
    status)
        status
		shift
        ;;
    -t|triage)
	triage ${@:2}
		shift
	;;
    bastion)
        bastion
	        shift
	;;    
   -a|--all)
       all
                shift
        ;;
    -h|--help)
        help_menu
                shift
        ;;
   *)
       echo "${1} is not a valid flag, try running: ${0} --help"
	   shift
       ;;
esac
shift

cd - > /dev/null
