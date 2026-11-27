{{- define "dhpreview.name" -}}datahub-pr-{{ required "prNumber" .Values.prNumber }}{{- end -}}
{{- define "dhpreview.host" -}}datahub-pr-{{ .Values.prNumber }}.gopreview.cbioportal.org{{- end -}}
{{/* The preview's databases: <db>, <db>_raw and <db>_ref. The prefix is
     inside the dev_cbioportal_go_pr* grants of the import user. */}}
{{- define "dhpreview.db" -}}dev_cbioportal_go_prdatahub{{ .Values.prNumber }}{{- end -}}
{{- define "dhpreview.labels" -}}
app.kubernetes.io/instance: {{ include "dhpreview.name" . }}
app.kubernetes.io/part-of: cbioportal-hub
{{- end -}}
{{- define "dhpreview.scheduling" -}}
nodeSelector:
  workload: cbio-dev
tolerations:
  - key: "workload"
    operator: "Equal"
    value: "cbio-dev"
    effect: "NoSchedule"
{{- end -}}
