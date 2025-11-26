{{- define "trivy-scanner.fullname" -}}
{{- printf "%s-%s" .Release.Name "trivy-scanner" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "trivy-scanner.labels" -}}
app.kubernetes.io/name: trivy-scanner
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: Helm
{{- end }}
