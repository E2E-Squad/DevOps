# syntax=docker/dockerfile:1
FROM node


COPY Web /E2E-Web

WORKDIR /E2E-Web

RUN npm install

WORKDIR /E2E-Web/styleguidist

RUN npm install

