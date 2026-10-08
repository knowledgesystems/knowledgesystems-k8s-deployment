{{- define "preview.name" -}}cbioportal-go-pr-{{ required "prNumber" .Values.prNumber }}{{- end -}}
{{- define "preview.host" -}}pr-{{ .Values.prNumber }}.gopreview.cbioportal.org{{- end -}}
{{- define "preview.sha" -}}{{ required "headSha" .Values.headSha | trunc 7 }}{{- end -}}
{{/* The image of the PR's head commit, pushed by cbioportal-go's docker.yml
     for PRs labelled `preview`. Until it exists, pods wait in
     ImagePullBackOff; the kubelet keeps retrying. */}}
{{- define "preview.image" -}}cbioportal/cbioportal-go:sha-{{ include "preview.sha" . }}{{- end -}}
{{- define "preview.db" -}}dev_cbioportal_go_pr{{ .Values.prNumber }}{{- end -}}
{{- define "preview.labels" -}}
app.kubernetes.io/instance: {{ include "preview.name" . }}
app.kubernetes.io/part-of: cbioportal-go-preview
{{- end -}}
{{- define "preview.scheduling" -}}
nodeSelector:
  workload: cbio-dev
tolerations:
  - key: "workload"
    operator: "Equal"
    value: "cbio-dev"
    effect: "NoSchedule"
{{- end -}}
{{/* GitHub App (hub-preview-bot) that reads the private PR and posts the
     Check Run and Deployment. */}}
{{- define "preview.ghEnv" -}}
- name: GH_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: hub-preview-bot
      key: client-id
- name: GH_INSTALLATION_ID
  valueFrom:
    secretKeyRef:
      name: hub-preview-bot
      key: installation-id
- name: GH_APP_KEY
  value: /etc/gh-app/key.pem
{{- end -}}
{{- define "preview.ghVolume" -}}
- name: gh-app-key
  secret:
    secretName: hub-preview-bot
    items:
      - key: private-key
        path: key.pem
{{- end -}}
