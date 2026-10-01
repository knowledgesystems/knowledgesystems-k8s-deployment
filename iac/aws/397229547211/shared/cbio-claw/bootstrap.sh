#!/bin/bash
set -euo pipefail

dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user
install -d -m 0755 /usr/local/lib/docker/cli-plugins
curl --fail --location --retry 3 \
  https://github.com/docker/compose/releases/download/v5.3.1/docker-compose-linux-aarch64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
echo 'aa611e811d0ea25897839c404bfb5bf93ce706dc51c500a4457890f5d0606a86  /usr/local/lib/docker/cli-plugins/docker-compose' | sha256sum -c -
chmod 0755 /usr/local/lib/docker/cli-plugins/docker-compose

install -d -o ec2-user -g ec2-user /home/ec2-user/work
runuser -u ec2-user -- git clone https://github.com/jamesqo/cbio-claw.git /home/ec2-user/work/cbio-claw
cd /home/ec2-user/work/cbio-claw
runuser -u ec2-user -- git checkout --detach 89ed45cf794e9ada3c952ceee6c21e78322cd19b
sed -i \
  -e 's/^HERMES_UID=.*/HERMES_UID=1000/' \
  -e 's/^HERMES_GID=.*/HERMES_GID=1000/' \
  -e 's|^REPO_ROOT=.*|REPO_ROOT=/home/ec2-user/work|' \
  docker-compose.env
install -d -m 0700 -o ec2-user -g ec2-user hermes-data
docker build -t hermes-cbio:0.1 -f docker/Dockerfile .

cat > docker-compose.profile.yml <<'COMPOSE'
services:
  hermes-cbio-gateway:
    command: ["hermes", "-p", "${HERMES_PROFILE:?Set HERMES_PROFILE}", "gateway", "run"]
    env_file: !override
      - ${HERMES_DATA}/profiles/${HERMES_PROFILE}/.env
    environment:
      CBIO_MAILING_REPLIES: "off"
    volumes:
      - ${HERMES_VAULT:?Install the pinned private vault}:/opt/cbio-claw/vault:ro
  hermes-cbio-dashboard:
    command: ["hermes", "-p", "${HERMES_PROFILE}", "dashboard", "--no-open", "--insecure", "--host", "0.0.0.0", "--port", "${HERMES_DASHBOARD_PORT}"]
    env_file: !override
      - ${HERMES_DATA}/profiles/${HERMES_PROFILE}/.env
    volumes:
      - ${HERMES_VAULT}:/opt/cbio-claw/vault:ro
COMPOSE
cat > profile.env <<'PROFILE'
HERMES_PROFILE=support
HERMES_VAULT=/home/ec2-user/work/cbio-claw-configuration/releases/f500968
PROFILE
chown ec2-user:ec2-user docker-compose.profile.yml profile.env

cat > /etc/systemd/system/cbio-claw.service <<'UNIT'
[Unit]
Description=cBio Claw native-profile gateway
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target
ConditionPathExists=/home/ec2-user/work/cbio-claw/profile.env

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user/work/cbio-claw
EnvironmentFile=/home/ec2-user/work/cbio-claw/profile.env
ExecStartPre=/bin/sh -c 'test -s "hermes-data/profiles/${HERMES_PROFILE}/.env" && test -s "hermes-data/profiles/${HERMES_PROFILE}/config.yaml" && test -f "${HERMES_VAULT}/presets/${HERMES_PROFILE}/config.skills.yaml"'
ExecStart=/usr/bin/docker compose --env-file docker-compose.env --env-file profile.env -f docker-compose.yml -f docker-compose.profile.yml up -d hermes-cbio-gateway
ExecStop=/usr/bin/docker compose --env-file docker-compose.env --env-file profile.env -f docker-compose.yml -f docker-compose.profile.yml stop hermes-cbio-gateway

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
