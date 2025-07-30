{{/*
Generic shard value lookup template
Usage: include "shard-demo.getShardValue" (dict "context" $shardingValues "fieldName" "eksasgmax" "defaultValue" "10")
*/}}
{{- define "shard-demo.getShardValue" -}}
{{- $runtimeShard := .context.shard }}
{{- $fieldName := .fieldName }}
{{- $defaultValue := .defaultValue }}
{{- $result := $defaultValue }}
{{- range .context.shardMapping }}
  {{- if eq .shard $runtimeShard }}
    {{- $fieldValue := index . $fieldName }}
    {{- if $fieldValue }}
      {{- $result = $fieldValue }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $result }}
{{- end }}

{{/*
Original specific template for comparison
*/}}
{{- define "shard-demo.eksasgmax" -}}
{{- $runtimeShard := .shard }}
{{- $eksasgmax := "10" }}
{{- range .shardMapping }}
  {{- if eq .shard $runtimeShard }}
    {{- if .eksasgmax }}
      {{- $eksasgmax = .eksasgmax }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $eksasgmax }}
{{- end }}
