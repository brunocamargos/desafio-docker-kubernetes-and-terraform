{{- define "mural.databaseUrl" -}}
postgres://{{ .Values.postgres.user }}:{{ .Values.postgres.password }}@postgres:5432/{{ .Values.postgres.database }}?sslmode=disable
{{- end }}
