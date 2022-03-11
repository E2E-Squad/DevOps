
APP_NAME	= e2e

COMPOSE		= -f docker-compose.yml
COMPOSE_PROD	= -f docker-compose.prod.yml
ENV_FILE	= --env-file srcs/.env

DOCKER		= docker-compose -p ${APP_NAME} ${COMPOSE}



all:			start setup-db



build:			#web styleguide db api
			${DOCKER} build --no-cache

start:
			${DOCKER} up -d


build-prod:		
			${DOCKER} ${COMPOSE_PROD} build --no-cache

start-prod:
			${DOCKER} ${COMPOSE_PROD} up -d


setup-db:
			${DOCKER} exec api python manage.py migrate --noinput
			${DOCKER} exec api python manage.py createsuperuser --noinput



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
			${DOCKER} down --volumes

re:			clean all

.PHONY:			all build build-prod start start-prod web styleguide api db up down clean re