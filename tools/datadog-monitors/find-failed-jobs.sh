#!/usr/bin/env bash
# Lists Job objects still in a failed state, which is what keeps the
# [k8s] CronJob failed monitor in ALERT. The metric is a gauge on the Job
# object, so a failure from weeks ago still reports until the object is gone.
#
# Usage: ./find-failed-jobs.sh [namespace]
set -euo pipefail

scope=(--all-namespaces)
[ $# -gt 0 ] && scope=(-n "$1")

kubectl get jobs "${scope[@]}" -o json | jq -r '
  .items[]
  | select((.status.failed // 0) > 0)
  | {
      ns:      .metadata.namespace,
      name:    .metadata.name,
      failed:  .status.failed,
      owner:   (.metadata.ownerReferences[0].name // "-- standalone --"),
      created: .metadata.creationTimestamp
    }
  | "\(.created)  \(.ns)/\(.name)\n    failed pods: \(.failed)   owned by: \(.owner)"
' | sort
