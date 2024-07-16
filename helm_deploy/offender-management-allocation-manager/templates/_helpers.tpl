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
