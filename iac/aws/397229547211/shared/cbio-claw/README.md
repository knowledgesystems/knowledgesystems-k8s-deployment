# cBio Claw dev node

Standalone Terraform root for a **new** cBio Claw EC2 gateway in the dev account
(`397229547211`, `us-east-1`). It neither imports nor modifies the existing
`hermes-agent-node` (`i-0aabed8506c3e7c31`), and does not change EKS or production.
The backend uses a dedicated state key. Referenced subnet, security groups, and
SSH key pair remain externally managed.

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
`1daa68efa156ba44c4e736e98c28495ae2649746`; builds `hermes-cbio:0.1`; and installs
an inactive systemd service. Check `/var/log/cloud-init-output.log` for bootstrap
errors. The private subnet needs outbound access to package repositories,
GitHub, Docker image registries, Slack, and model providers. Existing security
groups are reused; no additional inbound rules or public IP are created.

## Configuration and activation

Access the new `private_ip` output through the existing dev-network access path
using the `hermes-agent-node-key` key pair. The existing node's Tailscale identity
is not copied; provision a distinct identity if Tailscale access is needed.

The runtime is `/home/ec2-user/work/cbio-claw`. Install private runtime secrets
in `hermes-data/.env`, and model/Slack/channel configuration in
`hermes-data/config.yaml`, owned by UID/GID 1000. Keep secrets and authentication
files off this public repository and out of Terraform variables and user data.
The skill vault is `hermes-data/skills`, persisted with sessions and credentials
in `hermes-data` on the root disk. Select the intended skill bindings in the
private configuration; modular presets are tracked separately in `cbio-2qu`
and `cbio-e2h`.

Use separate test Slack credentials/channels while the existing node remains
active. Do not start two gateways with the same bot credentials. Set a strong
`API_SERVER_KEY` in the host's `docker-compose.env`; the source default is a test
key. Review access to the API port before activation. The dashboard stays off.
The existing host has local vendor patches for Slack handling that are not in
the pinned source revision. Review and port those changes through cBio Claw
before expecting equivalent forwarded-mail behavior from the new node.

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
gateway, back up and transfer consistent state/skills/secrets, then activate the
new gateway. Verify existing conversations and channel behavior before deciding
whether to retire anything. This PR does not perform cutover or retirement.

Terraform retains the new encrypted root disk on termination and blocks instance
destruction/replacement with `prevent_destroy`. User-data changes request
replacement and are therefore blocked until an explicit migration is planned.
Sizing changes stop/start only the new instance. Plan `instance_type=m8g.xlarge`
if monitored workloads require more capacity; review the plan before applying.
