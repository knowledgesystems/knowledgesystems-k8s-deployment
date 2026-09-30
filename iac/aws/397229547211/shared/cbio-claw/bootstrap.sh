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
runuser -u ec2-user -- git checkout --detach 1daa68efa156ba44c4e736e98c28495ae2649746
sed -i \
  -e 's/^HERMES_UID=.*/HERMES_UID=1000/' \
  -e 's/^HERMES_GID=.*/HERMES_GID=1000/' \
  -e 's|^REPO_ROOT=.*|REPO_ROOT=/home/ec2-user/work|' \
  docker-compose.env
install -d -m 0700 -o ec2-user -g ec2-user hermes-data
docker build -t hermes-cbio:0.1 -f docker/Dockerfile .

# Private configuration and a deliberate activation step are required before
# connecting a second gateway to Slack.
cat > /etc/systemd/system/cbio-claw.service <<'UNIT'
[Unit]
Description=cBio Claw gateway
Requires=docker.service
After=docker.service network-online.target
Wants=network-online.target
ConditionPathExists=/home/ec2-user/work/cbio-claw/hermes-data/.env
ConditionPathExists=/home/ec2-user/work/cbio-claw/hermes-data/config.yaml

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ec2-user/work/cbio-claw
ExecStart=/usr/bin/docker compose --env-file docker-compose.env up -d hermes-cbio-gateway
ExecStop=/usr/bin/docker compose --env-file docker-compose.env stop hermes-cbio-gateway

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
