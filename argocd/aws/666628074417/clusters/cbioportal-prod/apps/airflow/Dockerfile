ARG AIRFLOW_VERSION=2.10.5
ARG PYTHON_VERSION=3.12

FROM apache/airflow:${AIRFLOW_VERSION}

# Re-declare ARGs so they are available after FROM
ARG AIRFLOW_VERSION
ARG PYTHON_VERSION

USER root

# Install saml2aws binary
RUN curl -Lo /tmp/saml2aws.tar.gz \
      https://github.com/Versent/saml2aws/releases/download/v2.36.15/saml2aws_2.36.15_linux_amd64.tar.gz \
    && tar -xzf /tmp/saml2aws.tar.gz -C /usr/local/bin/ saml2aws \
    && chmod +x /usr/local/bin/saml2aws \
    && rm /tmp/saml2aws.tar.gz

USER airflow

# Install Python dependencies
# Use Airflow's constraint file to prevent pip from upgrading/downgrading
# core airflow packages, which would break the airflow entry point.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt \
    --constraint "https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt"
