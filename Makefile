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

PTRY			= cd API; poetry
ifeq (${ENV},local)
	DJ			= ${PTRY} run python manage.py
else
	DJ			= ${DOCKER} exec api python manage.py
endif

FIRST_TRGT		= $(firstword $(MAKECMDGOALS))
NEED_ARGS		= test dj
ifneq (, $(filter ${FIRST_TRGT}, ${NEED_ARGS}))
    _ARGS = $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
    $(eval $(_ARGS):;@:)
    ARGS = $(foreach arg,${_ARGS},$(subst +,--,${arg}))
endif

################################################################################
#                                    Functions                                 #
################################################################################

define setup_env
    $(eval ENV_FILE := srcs/$(1).env)
    @echo " - setup env $(ENV_FILE)"
    $(eval include srcs/$(1).env)
    $(eval export)
endef

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

test:
			echo ${ARGS}

setup-env:
			${call setup_env}

setup-db:
			${DJ} migrate --noinput
			${DJ} createsuperuser --noinput

check-python:
			@${PYTHON} -V | grep 3.10 || \
				(echo -e >&2 "${ERR}Python 3.10 is required${NC}"; false)
			@${PIP} -V | grep "python 3.10" || \
				(echo -e >&2 "${ERR}PIP for Python 3.10 is required${NC}"; false)

setup-python: check-python
			@echo -e "\n${BLU}Install poetry${NC}"
			@${PIP} install poetry | { grep Installing || echo -e "${OK}Already installed${NC}"; }
			@echo
			@${PTRY} install

dj: check-python db setup-env
			${DJ} ${ARGS}

ddj: db api
			${DJ} ${ARGS} 

local: setup-python db setup-env setup-db
			${DJ} runserver 0.0.0.0:8000

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
