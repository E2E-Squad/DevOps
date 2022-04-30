#!make

################################################################################
#                                     Colors                                   #
################################################################################

BLU		= \033[0;34m
CYN		= \033[0;36m
OK		= \033[0;32m
ERR		= \033[0;31m
WARN	= \033[0;33m
NC		= \033[m

################################################################################
#                                     Config                                   #
################################################################################

include .env

APP_NAME		= e2e
COMPOSE_DEV		= -f docker-compose.yml
COMPOSE_PROD	= -f docker-compose.yml -f docker-compose.prod.yml
SHELL			= bash 

# Define docker-compose command to run
ifeq (${ENV},local)
	DOCKER		= docker-compose -p ${APP_NAME}
else ifeq (${ENV},docker-dev)
	DOCKER		= docker-compose -p ${APP_NAME} ${COMPOSE_DEV}
else ifeq (${ENV},docker-prod)
	DOCKER		= docker-compose -p ${APP_NAME} ${COMPOSE_PROD}
else
	DOCKER		= @echo "$(ERR)ENV is not defined$(NC)", cannot execute: 
endif

# Define python and pip executables 
PYTHON			= $(shell which python3)
ifeq (${PYTHON},)
	PYTHON		= $(shell which python)
endif
# Define python and pip executables 
PIP				= $(shell which pip3)
ifeq (${PYTHON},)
	PIP			= $(shell which pip)
endif
################################################################################
#                                    Functions                                 #
################################################################################

################################################################################
#                                      Rules                                   #
################################################################################

all:		start setup-db

pull:
			${DOCKER} pull

build:
			${DOCKER} build --no-cache

start:
			${DOCKER} up -d

build-prod:		
			${DOCKER} ${COMPOSE_PROD} build --no-cache

start-prod:
			${DOCKER} ${COMPOSE_PROD} up -d

down-prod:
			${DOCKER} ${COMPOSE_PROD} down

setup-db:
			${DOCKER} exec api python manage.py migrate --noinput
			${DOCKER} exec api python manage.py createsuperuser --noinput

check-python:
			@${PYTHON} -V | grep 3.10 || \
				(echo -e >&2 "${ERR}Python 3.10 is required${NC}"; false)
			@${PIP} -V | grep "python 3.10" || \
				(echo -e >&2 "${ERR}PIP for Python 3.10 is required${NC}"; false)

setup-python: check-python
			@echo "Setup Python for local dev"
			@cd API; pwd; poetry install

web:
			${DOCKER} build web
			${DOCKER} up -d web

styleguide:
			${DOCKER} build styleguidist
			${DOCKER} up -d styleguidist

api:
			${DOCKER} build api
			${DOCKER} up -d api

db:
			${DOCKER} build db 
			${DOCKER} up -d db

down:
			${DOCKER} down

clean:		
ifeq ($(ENV),docker-prod)
			@echo "${ERR}Cannot automatically clean on prod ENV${NC}"
else
			${DOCKER} down --volumes
			${DOCKER} rm -f
endif

re:			clean all

.PHONY:		all build build-prod start start-prod web styleguide api db up down clean re
