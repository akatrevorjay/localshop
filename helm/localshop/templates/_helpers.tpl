{{/*
Expand the name of the chart.
*/}}
{{- define "localshop.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "localshop.fullname" -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Dump localshop env as yaml
*/}}
{{- define "localshop.env" -}}
{{- range $k, $v := .Values.localshop.env }}
{{ $k }}: {{ quote $v -}}
{{ end -}}
{{- end -}}

{{- define "toYamlMap" -}}
{{- range $k, $v := .resources }}
{{ $k }}: {{ quote $v -}}
{{ end -}}
{{- end -}}

{{/*
Dump localshop pod config to utilize our config and secret maps
*/}}
{{- define "localshop.appenv" }}
envFrom:
- configMapRef:
    # Oh yeah, yaml mappings are amazing. ( double indent )
    name: {{ include "localshop.fullname" . }}-config
- secretRef:
    # Oh yeah, yaml mappings are amazing. ( double indent )
    name: {{ include "localshop.fullname" . }}-secrets

##
## env
##
env:

- name: HELM_RELEASE_REVISION
  value: {{ quote .Release.Revision }}
- name: HELM_RELEASE_REVISION_TYPE
  value: {{ if .Release.IsUpgrade }}upgrade{{ else if .Release.IsInstall }}install{{ else }}unknown{{ end }}
- name: HELM_RELEASE_HERITAGE
  value: {{ quote .Release.Service }}
- name: HELM_RELEASE_NAME
  value: {{ quote .Release.Name }}
- name: HELM_CHART
  value: {{ .Chart.Name }}-{{ .Chart.Version }}
- name: HELM_CHART_NAME
  value: {{ .Chart.Name }}
- name: HELM_CHART_VERSION
  value: {{ .Chart.Version }}
- name: HELM_RELEASE_FULLNAME
  value: {{ include "localshop.fullname" . | quote }}

# Give pod info in nice vars
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: POD_IP
  valueFrom:
    fieldRef:
      fieldPath: status.podIP

# - name: CONTAINER_CPU_REQUEST
#   valueFrom:
#     fieldRef:
#       fieldPath: requests.cpu
# - name: CONTAINER_CPU_LIMIT
#   valueFrom:
#     fieldRef:
#       fieldPath: limits.cpu
# - name: CONTAINER_MEM_REQUEST
#   valueFrom:
#     fieldRef:
#       fieldPath: requests.memory
# - name: CONTAINER_MEM_LIMIT
#   valueFrom:
#     fieldRef:
#       fieldPath: limits.memory

{{ end -}}

{{- /*
chartref prints a chart name and version.
It does minimal escaping for use in Kubernetes labels.
Example output:
  zookeeper-1.2.3
  wordpress-3.2.1_20170219
*/ -}}
{{- define "localshop.chartref" -}}
  {{- replace "+" "_" .Chart.Version | printf "%s-%s" .Chart.Name -}}
{{- end -}}

{{/*
Generate chart labels

revision: {{ quote .Release.Revision }}
revision_type: {{ if .Release.IsUpgrade }}upgrade{{ else if .Release.IsInstall }}install{{ else }}unknown{{ end }}
*/}}
{{- define "localshop.chartlabels" -}}
heritage: {{ quote .Release.Service }}
release: {{ quote .Release.Name }}
chart: {{ .Chart.Name }}-{{ .Chart.Version }}
fullname: {{ include "localshop.fullname" . | quote }}
{{- end -}}

{{/*
Generate app labels
*/}}
{{- define "localshop.applabels" -}}
{{ template "localshop.chartlabels" . }}
localshop.service: {{ template "localshop.fullname" . }}
component: {{ template "localshop.fullname" . }}
{{- end -}}

{{/*
App name
*/}}
{{- define "localshop.appname" -}}
{{ template "localshop.fullname" . }}
{{- end -}}

{{/* vim: set filetype=yaml.gotemplate : */}}
