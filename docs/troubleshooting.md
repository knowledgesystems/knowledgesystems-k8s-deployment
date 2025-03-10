---
icon: tools
---
# Troubleshooting
This list is used to track issues and their remedies.

## Datadog failed to auto-detect cluster name
When deployed on AWS EC2 nodes using the `BOTTLEROCKET_*` AMI types, Datadog fails to auto-detect the cluster name, resulting in the following errors:
```shell
2025-03-10 17:39:09 UTC | CLUSTER | WARN | (subcommands/start/command.go:235 in start) | Failed to auto-detect a Kubernetes cluster name. We recommend you set it manually via the cluster_name config option
2025-03-10 17:39:10 UTC | CLUSTER | ERROR | (pkg/collector/corechecks/loader.go:64 in Load) | core.loader: could not configure check orchestrator: orchestrator check is configured but the cluster name is empty
2025-03-10 17:39:10 UTC | CLUSTER | ERROR | (pkg/collector/scheduler.go:208 in getChecks) | Unable to load a check from instance of config 'orchestrator': Core Check Loader: Could not configure check orchestrator: orchestrator check is configured but the cluster name is empty
```

To solve this, either use the `AL2_*` AMI type (NOT RECOMMENDED) or manually specify the cluster name in the Datadog helm values:
```yaml
datadog:
  clusterName: <cluster-name>
```

## Datadog always out-of-sync with helm and argocd

By default, Datadog auto-assigns random values to the following on restarts:
1. Token used for authentication between the cluster agent and node agents.
2. Configmap for the APM Instrumentation KPIs.

This leads to Datadog being permanently out-of-sync when deployed with Helm and ArgoCD. To solve this issue, follow the steps below:

1. Provide a cluster agent token as a secret.
   * Generate a random 32-digit hexadecimal number.
        ```shell
        openssl rand -hex 32
        ```
   * Create a secret with the number generated above.
        ```yaml
        apiVersion: v1
        kind: Secret
        metadata:
          name: datadog
        stringData:
          token: <random-hex-32>
        ```
   * Use existing secret in Datadog helm values.
        ```yaml
        clusterAgent:
          tokenExistingSecret: datadog
        ```
2. Disable API Instrumentation KPIs by setting the `datadog.apm.instrumentation.skipKPITelemetry` to `false` in the datadog helm values.
    ```yaml
    datadog:
      apm:
        instrumentation:
          skipKPITelemetry: true
    ```