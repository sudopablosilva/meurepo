# Template Helm Reutilizável para Configuração de Shards

Este projeto demonstra como criar templates Helm reutilizáveis para evitar duplicação de código ao trabalhar com configurações específicas de shards.

## 📋 Índice

- [Problema Resolvido](#problema-resolvido)
- [Solução Implementada](#solução-implementada)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Como Usar](#como-usar)
- [Testando o Template](#testando-o-template)
- [Resultados Esperados](#resultados-esperados)
- [Exemplos Práticos](#exemplos-práticos)

## 🎯 Problema Resolvido

Antes desta solução, era necessário criar múltiplos templates específicos para cada campo:

```yaml
{{- define "versions.eksasgmax" -}}
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

{{- define "versions.eksasgmin" -}}
{{- $runtimeShard := .shard }}
{{- $eksasgmin := "1" }}
{{- range .shardMapping }}
  {{- if eq .shard $runtimeShard }}
    {{- if .eksasgmin }}
      {{- $eksasgmin = .eksasgmin }}
    {{- end }}
  {{- end }}
{{- end }}
{{- $eksasgmin }}
{{- end }}
```

Isso resultava em **código duplicado** e **manutenção complexa**.

## ✅ Solução Implementada

Criamos um template genérico que funciona para qualquer campo:

```yaml
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
```

## 📁 Estrutura do Projeto

```
shard-demo/
├── Chart.yaml                    # Metadados do chart
├── values.yaml                   # Configurações dos shards
└── templates/
    ├── _helpers.tpl              # Templates reutilizáveis
    ├── configmap.yaml            # Exemplo de uso em ConfigMap
    └── deployment.yaml           # Exemplo de uso em Deployment
```

## 🚀 Como Usar

### 1. Configuração dos Shards (values.yaml)

```yaml
shardingValues:
  shard: "prod-us-east-1"          # Shard atual
  shardMapping:
    - shard: "dev-us-west-2"
      eksasgmax: "5"
      eksasgmin: "1"
      eksasgdesired: "2"
      instanceType: "t3.small"
    - shard: "prod-us-east-1"
      eksasgmax: "20"
      eksasgmin: "3"
      eksasgdesired: "10"
      instanceType: "m5.large"
    - shard: "prod-eu-west-1"
      eksasgmax: "15"
      eksasgmin: "2"
      eksasgdesired: "8"
      instanceType: "m5.medium"
```

### 2. Uso nos Templates

**Sintaxe:**
```yaml
{{ include "shard-demo.getShardValue" (dict "context" $shardingValues "fieldName" "NOME_DO_CAMPO" "defaultValue" "VALOR_PADRÃO") }}
```

**Exemplos práticos:**
```yaml
# Em um Deployment
env:
- name: EKS_ASG_MAX
  value: "{{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "eksasgmax" "defaultValue" "10") }}"
- name: INSTANCE_TYPE
  value: "{{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "instanceType" "defaultValue" "t3.micro") }}"

# Em um ConfigMap
data:
  eks-asg-max: "{{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "eksasgmax" "defaultValue" "10") }}"
  eks-asg-min: "{{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "eksasgmin" "defaultValue" "1") }}"
```

## 🧪 Testando o Template

### Pré-requisitos
- Helm 3.x instalado
- Acesso ao terminal

### Comandos de Teste

#### 1. Teste com Shard Padrão (prod-us-east-1)
```bash
cd helm-template-test/shard-demo
helm template . --debug
```

#### 2. Teste com Shard de Desenvolvimento
```bash
helm template . --set shardingValues.shard="dev-us-west-2"
```

#### 3. Teste com Shard Inexistente (valores padrão)
```bash
helm template . --set shardingValues.shard="shard-inexistente"
```

#### 4. Teste com Shard Europeu
```bash
helm template . --set shardingValues.shard="prod-eu-west-1"
```

## 📊 Resultados Esperados

### Teste 1: Shard Produção US East (prod-us-east-1)
```yaml
# ConfigMap
data:
  current-shard: "prod-us-east-1"
  eks-asg-max: "20"
  eks-asg-min: "3"
  eks-asg-desired: "10"
  instance-type: "m5.large"

# Deployment
env:
- name: SHARD_NAME
  value: "prod-us-east-1"
- name: EKS_ASG_MAX
  value: "20"
- name: EKS_ASG_MIN
  value: "3"
- name: INSTANCE_TYPE
  value: "m5.large"
```

### Teste 2: Shard Desenvolvimento (dev-us-west-2)
```yaml
# ConfigMap
data:
  current-shard: "dev-us-west-2"
  eks-asg-max: "5"
  eks-asg-min: "1"
  eks-asg-desired: "2"
  instance-type: "t3.small"

# Deployment
env:
- name: SHARD_NAME
  value: "dev-us-west-2"
- name: EKS_ASG_MAX
  value: "5"
- name: EKS_ASG_MIN
  value: "1"
- name: INSTANCE_TYPE
  value: "t3.small"
```

### Teste 3: Shard Inexistente (valores padrão)
```yaml
# ConfigMap
data:
  current-shard: "shard-inexistente"
  eks-asg-max: "10"        # Valor padrão
  eks-asg-min: "1"         # Valor padrão
  eks-asg-desired: "5"     # Valor padrão
  instance-type: "t3.micro" # Valor padrão

# Deployment
env:
- name: SHARD_NAME
  value: "shard-inexistente"
- name: EKS_ASG_MAX
  value: "10"              # Valor padrão
- name: EKS_ASG_MIN
  value: "1"               # Valor padrão
- name: INSTANCE_TYPE
  value: "t3.micro"        # Valor padrão
```

### Teste 4: Shard Europa (prod-eu-west-1)
```yaml
# ConfigMap
data:
  current-shard: "prod-eu-west-1"
  eks-asg-max: "15"
  eks-asg-min: "2"
  eks-asg-desired: "8"
  instance-type: "m5.medium"

# Deployment
env:
- name: SHARD_NAME
  value: "prod-eu-west-1"
- name: EKS_ASG_MAX
  value: "15"
- name: EKS_ASG_MIN
  value: "2"
- name: INSTANCE_TYPE
  value: "m5.medium"
```

## 💡 Exemplos Práticos

### Exemplo 1: Configuração de Auto Scaling Group
```yaml
# Em um template de NodeGroup
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
spec:
  nodeGroups:
  - name: workers
    minSize: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "eksasgmin" "defaultValue" "1") }}
    maxSize: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "eksasgmax" "defaultValue" "10") }}
    desiredCapacity: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "eksasgdesired" "defaultValue" "5") }}
    instanceType: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "instanceType" "defaultValue" "t3.micro") }}
```

### Exemplo 2: Configuração de Recursos
```yaml
# Em um Deployment
resources:
  requests:
    cpu: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "cpuRequest" "defaultValue" "100m") }}
    memory: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "memoryRequest" "defaultValue" "128Mi") }}
  limits:
    cpu: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "cpuLimit" "defaultValue" "500m") }}
    memory: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "memoryLimit" "defaultValue" "512Mi") }}
```

### Exemplo 3: Configuração de Banco de Dados
```yaml
# Em um ConfigMap para configuração de DB
data:
  database-host: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "dbHost" "defaultValue" "localhost") }}
  database-port: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "dbPort" "defaultValue" "5432") }}
  database-name: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "dbName" "defaultValue" "myapp") }}
  connection-pool-size: {{ include "shard-demo.getShardValue" (dict "context" .Values.shardingValues "fieldName" "dbPoolSize" "defaultValue" "10") }}
```

## 🎉 Vantagens da Solução

1. **Reutilização de Código**: Um único template para todos os campos
2. **Manutenção Simplificada**: Alterações em um local apenas
3. **Flexibilidade**: Funciona com qualquer campo e valor padrão
4. **Consistência**: Mesmo comportamento para todas as consultas
5. **Legibilidade**: Código mais limpo e fácil de entender
6. **Escalabilidade**: Fácil adição de novos shards e campos

## 🔧 Personalização

Para usar este padrão em seus próprios projetos:

1. Copie o template `getShardValue` para seu `_helpers.tpl`
2. Ajuste o nome do template para seu chart (ex: `meu-chart.getShardValue`)
3. Configure seus shards no `values.yaml`
4. Use o template em seus recursos Kubernetes

## 📝 Notas Importantes

- **Valores Padrão**: Sempre forneça valores padrão sensatos
- **Nomes de Campos**: Use nomes consistentes nos shards
- **Validação**: Considere adicionar validação para campos obrigatórios
- **Documentação**: Documente os campos disponíveis para cada shard

---

**Desenvolvido para demonstrar boas práticas em templates Helm reutilizáveis** 🚀
