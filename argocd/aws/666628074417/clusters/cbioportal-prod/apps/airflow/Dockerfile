FROM apache/airflow:2.9.2

USER root

# Install saml2aws binary
RUN curl -Lo /tmp/saml2aws.tar.gz \
      https://github.com/Versent/saml2aws/releases/download/v2.36.15/saml2aws_2.36.15_linux_amd64.tar.gz \
    && tar -xzf /tmp/saml2aws.tar.gz -C /usr/local/bin/ saml2aws \
    && chmod +x /usr/local/bin/saml2aws \
    && rm /tmp/saml2aws.tar.gz

USER airflow

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
