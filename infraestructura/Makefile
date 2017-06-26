.PHONY: start stop status logs restart nuke

########################################
##            Variables               ##
########################################
SHELL := $(shell which bash)
PROJECT_NAME:=$(shell cat ../.project-name)
DATA_DIRECTORY:=$(CURDIR)/../data
DB_DIRECTORY:=$(CURDIR)/../db

IMAGES: db

########################################
##             Control                ##
########################################


start: setup

setup: create up


up: .running

.running:
	@docker-compose --project-name ${PROJECT_NAME} build
	@docker-compose --project-name ${PROJECT_NAME} up -d
	@touch .running


create: .data_built .network_built


.data_built:
	echo ${DATA_DIRECTORY}
	[ -d ${DATA_DIRECTORY} ] && docker volume create --name ${PROJECT_NAME}_data --opt type=none --opt device=${DATA_DIRECTORY} --opt o=bind
	[ -d ${DB_DIRECTORY} ] && docker volume create --name ${PROJECT_NAME}_db --opt type=none --opt device=${DB_DIRECTORY} --opt o=bind
	@touch .data_built

.network_built:
	@docker network create ${PROJECT_NAME}_net
	@touch .network_built


.infrastructure_built:
	@docker-compose --project-name ${PROJECT_NAME} build
	@touch .infrastructure_built


stop:
	docker-compose --project-name ${PROJECT_NAME} stop
	@rm -rf .running || true

status:
	@docker-compose --project-name ${PROJECT_NAME} ps

logs:
	@docker-compose --project-name ${PROJECT_NAME} logs


restart: stop clean start status

clean: stop clean_containers clean_data clean_network

nuke: clean clean_images

clean_images:
	@for image in $(IMAGES); do \
	  docker rmi citibike/$$image ; \
	done

clean_containers:
	@docker-compose --project-name ${PROJECT_NAME} down --volumes --remove-orphans
	@docker-compose --project-name ${PROJECT_NAME} rm -f -v
	@rm -rf .infrastructure_built || true

clean_data:
	@docker volume rm ${PROJECT_NAME}_db
	@docker volume rm ${PROJECT_NAME}_data
	@rm -rf .data_built || true

clean_network: stop
	@docker network rm ${PROJECT_NAME}_net
	@rm -rf .network_built || true
