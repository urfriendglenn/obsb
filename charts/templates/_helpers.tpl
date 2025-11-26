{{/*
Generate a standardized name for resources
*/}}
{{- define "obsb.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Short name helper
*/}}
{{- define "obsb.name" -}}
{{ .Chart.Name }}
{{- end }}

{{/*
Labels
*/}}
{{- define "obsb.labels" -}}
app.kubernetes.io/name: {{ include "obsb.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: Helm
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
