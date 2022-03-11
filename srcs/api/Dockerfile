## syntax=docker/dockerfile:1
FROM python:3.9


COPY API /app

WORKDIR /app/E2E


ENV PYTHONPATH=${PYTHONPATH}:${PWD}
RUN pip3 install poetry

RUN poetry config virtualenvs.create false

RUN poetry add psycopg2-binary
RUN poetry add gunicorn

RUN poetry install --no-dev