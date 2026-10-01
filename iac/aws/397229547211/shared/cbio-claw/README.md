# cBio Claw dev node

Standalone Terraform root for a **new** cBio Claw EC2 gateway in the dev account
(`397229547211`, `us-east-1`). It neither imports nor modifies the existing
`hermes-agent-node` (`i-0aabed8506c3e7c31`), and does not change EKS or production.
The backend uses a dedicated state key. Referenced subnet, security groups, and
SSH key pair remain externally managed.

The instance is on-demand, avoiding the existing node's Spot-capacity interruptions.
The default is `m8g.large` (2 ARM vCPUs, 8 GiB RAM), half the CPU and RAM of the
existing `m8g.xlarge`. An idle observation on 2026-09-30 showed approximately
192 MiB for the current gateway container and 394 MiB used on the host. This is
not a peak-load measurement: monitor memory during concurrent conversations and
image builds. Local inference needs a separate capacity assessment.
The new encrypted gp3 root disk is 40 GiB; the existing node used about 11 GiB
of its 160 GiB disk. Neither the old instance nor its disk is resized.

## Review and eventual provisioning

This change is configuration only. Do not apply it until deployment is separately
authorized. Run from this directory with dev-account credentials:

```sh
export AWS_PROFILE=dev
export TF_VAR_AWS_PROFILE=dev
aws sts get-caller-identity
terraform init
terraform fmt -check
terraform validate
terraform plan -out=cbio-claw.tfplan
```

The plan must create **one new instance**, modify/destroy none, and never mention
`i-0aabed8506c3e7c31` as a managed resource. Verify the backend bucket grants access
to the new state key and its `.tflock` object. After separate authorization,
apply the reviewed plan. No Terraform provisioners execute remote commands.

The pinned AMI is Amazon Linux 2023 ARM64. Cloud-init installs Docker, a pinned
Compose release, and Git; checks out cBio Claw commit
`89ed45cf794e9ada3c952ceee6c21e78322cd19b`; builds `hermes-cbio:0.1`; and installs
an inactive systemd service. Check `/var/log/cloud-init-output.log` for bootstrap
errors. The private subnet needs outbound access to package repositories,
GitHub, Docker image registries, Slack, and model providers. Existing security
groups are reused; no additional inbound rules or public IP are created.

## Configuration and activation

Access the new `private_ip` output through the existing dev-network access path
using the `hermes-agent-node-key` key pair. The existing node's Tailscale identity
is not copied; provision a distinct identity if Tailscale access is needed.

The runtime is `/home/ec2-user/work/cbio-claw`. Bootstrap writes a Compose
profile override and `profile.env`, defaulting to `HERMES_PROFILE=support`.
The command explicitly invokes `hermes -p support gateway run`; credentials
come only from `hermes-data/profiles/support/.env`. The root/default profile's
credentials are not inherited through Compose. The dashboard uses the same
selected profile and remains off. Automatic mailing-list replies are held off
by `CBIO_MAILING_REPLIES=off`; activation is a separate reviewed change.

Install the private cBioPortal/cbio-claw-configuration vault release `f500968`
at `/home/ec2-user/work/cbio-claw-configuration/releases/f500968`. Transfer a
reviewed archive through an authorized access path; bootstrap does not fetch
private repositories or embed a GitHub token. Compose mounts that release at
`/opt/cbio-claw/vault:ro`. `profile.env` contains the profile name and vault path,
not secrets. Update its vault path deliberately for later reviewed releases.

Create the support profile using native Hermes, without starting a gateway:

```sh
cd /home/ec2-user/work/cbio-claw
sudo docker run --rm --network none --user 1000:1000 \
  --entrypoint hermes -e HERMES_HOME=/opt/data \
  -v "$PWD/hermes-data:/opt/data" hermes-cbio:0.1 \
  profile create support --no-skills --no-alias
```

Install private `.env`, model/provider/Slack config, authentication and SOUL in
`hermes-data/profiles/support`, owned by UID/GID 1000. Set secret files to mode
0600. Merge the vault's `presets/support/config.skills.yaml` fragment into the
profile config, preserving its other settings. It loads the support and shared
skill directories: six curated skills, with `.no-bundled-skills` and an empty
profile-local `skills/` directory. Engineering loads engineering/shared for
seventeen skills. Use the vault's native-profile tests to verify the catalog.
Skills, config files and Terraform user data must not contain secret values.

For an engineering gateway, create `engineering` instead, merge its matching
fragment, provide the separate Hermes Engineer bot credentials, and select
`HERMES_PROFILE=engineering` in `profile.env`. This service runs one selected
profile per host. Concurrent support/engineering gateways require separately
configured containers with distinct names, ports, and credentials; starting
this service twice does not create two bots.

Use separate test Slack credentials/channels while the existing node remains
active. Never run two gateways with the same bot credentials. Set a strong
`API_SERVER_KEY` in the host's `docker-compose.env`; the source default is a test
key. Review API-port access before activation. Renew expired MCP OAuth before
enabling that server; `mcp_servers.cbioportal-db.enabled: false` can defer an
unavailable database MCP connection so it does not delay Slack startup.

The pinned runtime includes the reviewed attachment-aware mailing-list extension,
but the kill switch keeps it disabled. Existing host-local vendor patches are
not copied by bootstrap; compare the reviewed runtime with those patches before
cutover. Profile and vault loading use native Hermes, with no preset loader.

After explicit activation approval and private configuration installation:

```sh
sudo systemctl enable --now cbio-claw
sudo systemctl status cbio-claw
sudo docker logs --tail=100 hermes-cbio-gateway
free -m
```

Verify model access, Slack connectivity with test credentials, skill loading,
and persistence across a service restart. Bootstrap never enables or starts
the service. Docker's Compose restart policy maintains the container after
activation; systemd starts it on subsequent boots.

## Updates, state migration, and rollback

Record the deployed commit/image IDs. Stop the service and take a completed EBS
snapshot before source/configuration updates so SQLite state is consistent.
Deploy reviewed source and private configuration, rebuild the image, and start
the service. Restore the previous source/image/configuration for rollback;
restore state only with the gateway stopped.

Any future cutover from the existing node is a separate operation: stop its
gateway, back up and transfer the complete consistent support profile (including
SQLite databases, sessions, memories, pairing and authentication), then activate the
new gateway. Verify existing conversations and channel behavior before deciding
whether to retire anything. This PR does not perform cutover or retirement.

Terraform retains the new encrypted root disk on termination and blocks instance
destruction/replacement with `prevent_destroy`. User-data changes request
replacement and are therefore blocked until an explicit migration is planned.
Sizing changes stop/start only the new instance. Plan `instance_type=m8g.xlarge`
if monitored workloads require more capacity; review the plan before applying.
