FROM apache/airflow:latest-python3.11
USER root

# The Airflow image is based on Debian
# needed for python2
RUN echo "deb http://archive.debian.org/debian/ stretch contrib main non-free" | sudo tee /etc/apt/sources.list.d/docker.list
# needed for java 21
RUN echo "deb https://deb.debian.org/debian/ unstable main contrib non-free" | sudo tee /etc/apt/sources.list.d/docker.list

# Install git, git-lfs, python2
# TODO: Remove dependency on python2
RUN curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         git git-lfs python2.7 openjdk-21-jdk maven vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Symlink python(2.7) to python2
#RUN which python
RUN ln -s /home/airflow/.local/bin/python /home/airflow/.local/bin/python2

# Install requests library for python2
# TODO: Remove dependency on python2
RUN curl https://files.pythonhosted.org/packages/0a/00/8cc925deac3a87046a4148d7846b571cf433515872b5430de4cd9dea83cb/requests-2.7.0.tar.gz --output requests-2.7.0.tar.gz \
  && tar -xvf requests-2.7.0.tar.gz \
  && cd requests-2.7.0 \
  && python2 setup.py install \
  && cd .. \
  && rm requests-2.7.0.tar.gz \
  && rm -rf requests-2.7.0

USER airflow

# Git lfs setup
RUN git lfs install --skip-repo --skip-smudge

# Install python3 requirements
COPY requirements.txt /
RUN python3 -m pip install --upgrade pip
#RUN pip3 install --upgrade pip
RUN pip3 install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /requirements.txt
RUN pip3 uninstall -y google-cloud-bigquery-storage
