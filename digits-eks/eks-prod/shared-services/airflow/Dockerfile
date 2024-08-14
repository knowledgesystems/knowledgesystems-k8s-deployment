FROM apache/airflow:latest
USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         git git-lfs vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*
