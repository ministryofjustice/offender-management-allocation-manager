{{/* vim: set filetype=mustache: */}}

{{/*
  Just a helper for naming consistency as we've defined a second
  helper below to disable prometheus metrics.
*/}}
{{- define "moic-helpers.envs" -}}
{{- include "deployment.envs" (index .Values "generic-service") }}
{{- end }}

{{/*
  Disable prometheus metrics by replacing its variable name.
  This must be done in some templates where we don't want or care for metrics
  because these are enabled by default when using `include "deployment.envs"`.
*/}}
{{- define "moic-helpers.envs_without_prometheus_metrics" -}}
{{- include "deployment.envs" (index .Values "generic-service") | replace "PROMETHEUS_METRICS" "PROMETHEUS_METRICS_DISABLED" }}
{{- end }}

{{/*
  Reuse the shared application image pull policy across custom workloads.
*/}}
{{- define "moic-helpers.image_pull_policy" -}}
{{- with index .Values "generic-service" -}}
{{ .image.pullPolicy | default "IfNotPresent" }}
{{- end -}}
{{- end }}

{{/*
  Render a CronJob using the local shared cronjob conventions.
*/}}
{{- define "moic-helpers.cronjob" -}}
{{- $root := .root -}}
{{- $key := .key -}}
{{- $cronjob := .cronjob -}}
{{- $cronjobName := $key | replace "_" "-" -}}
{{- $cronjobSchedule := required (printf "cronjobs.%s.schedule must be set when enabled" $key) $cronjob.schedule -}}
{{- $cronjobCommand := required (printf "cronjobs.%s.command must be set" $key) $cronjob.command -}}
apiVersion: batch/v1
kind: CronJob
metadata:
  name: {{ $cronjobName }}
spec:
  schedule: {{ $cronjobSchedule | quote }}
  concurrencyPolicy: Replace
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 3
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: {{ index $root.Values "generic-service" "serviceAccountName" }}
          restartPolicy: OnFailure
          securityContext:
            {{- with index $root.Values "generic-service" }}{{ toYaml .podSecurityContext | nindent 12 }}{{ end }}
          containers:
          - name: {{ $cronjobName }}
            image: {{ with index $root.Values "generic-service" }}{{ .image.repository }}:{{ .image.tag }}{{ end }}
            imagePullPolicy: {{ include "moic-helpers.image_pull_policy" $root }}
            securityContext:
              {{- with index $root.Values "generic-service" }}{{ toYaml .securityContext | nindent 14 }}{{ end }}
            command: ["sh", "-c", {{ $cronjobCommand | quote }}]
              {{- include "moic-helpers.envs_without_prometheus_metrics" $root | nindent 12 }}
            resources:
              {{- toYaml $root.Values.cronjob_resources | nindent 14 }}
{{ end }}
