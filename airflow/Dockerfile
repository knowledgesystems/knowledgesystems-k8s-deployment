FROM apache/airflow:latest
USER root

# Install vim on scheduler pod to make reading text files less painful
# TODO: figure out how to run `sudo apt-get install ...` inside the container
# so we don't have to do in the Docker image
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# Install python3 requirements
# This is for the scheduler/webserver only-- worker pod dependencies are managed separately
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir apache-airflow==${AIRFLOW_VERSION} kubernetes
