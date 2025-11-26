{{/*
Return true if the given stack has log monitoring enabled.
*/}}
{{- define "obsb.stack.logsEnabled" -}}
{{- if and .logs .logs.enabled }}true{{ else }}false{{ end }}
{{- end }}

{{/*
Return true if the given stack has metrics monitoring enabled.
*/}}
{{- define "obsb.stack.metricsEnabled" -}}
{{- if and .metrics .metrics.enabled }}true{{ else }}false{{ end }}
{{- end }}

{{/*
Return true if the stack's metrics mode is daemonset.
*/}}
{{- define "obsb.stack.metricsDaemonset" -}}
{{- if and .metrics (eq .metrics.mode "daemonset") }}true{{ else }}false{{ end }}
{{- end }}

{{/*
Return true if the stack's metrics mode is sidecar.
*/}}
{{- define "obsb.stack.metricsSidecar" -}}
{{- if and .metrics (eq .metrics.mode "sidecar") }}true{{ else }}false{{ end }}
{{- end }}

{{/*
Derive the Fluent Bit log path for a given stack.
*/}}
{{- define "obsb.stack.logPath" -}}
/var/log/containers/*{{ .namespace }}*.log
{{- end }}

{{/*
Make a valid Kubernetes name for resources generated per-stack.
*/}}
{{- define "obsb.stack.resourceName" -}}
{{ printf "%s-%s" (include "obsb.name" $) .name | trunc 63 | trimSuffix "-" }}
{{- end }}
