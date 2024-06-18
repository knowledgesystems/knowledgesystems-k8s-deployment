FROM apache/airflow:latest
USER root

# The Airflow image is based on Debian
# needed for java 21
RUN echo "deb https://deb.debian.org/debian/ unstable main contrib non-free" | sudo tee /etc/apt/sources.list.d/docker.list

# Install dependencies
# (vim is so we can ssh ito the worker pods and inspect files)
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         git git-lfs maven vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER airflow

# Git lfs setup
RUN git lfs install --skip-repo --skip-smudge

# Install python3 requirements
COPY requirements.txt /
RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt
RUN pip3 uninstall -y google-cloud-bigquery-storage
