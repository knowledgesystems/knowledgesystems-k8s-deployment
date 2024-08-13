FROM apache/airflow:latest
USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         git git-lfs vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# Install python3 requirements
# This is for the scheduler/webserver only-- worker pod dependencies are managed separately
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir apache-airflow==${AIRFLOW_VERSION} kubernetes
