# 🎓 UniPlus - Infraestrutura como Código (IaC)

Este repositório contém a definição completa da infraestrutura Cloud para o ecossistema **UniPlus**, utilizando **Terraform** para o provisionamento na AWS (us-east-1). O projeto foca em alta disponibilidade, processamento serverless e monitoramento avançado.

## 🏗️ Arquitetura do Sistema

A infraestrutura foi desenhada seguindo as melhores práticas de isolamento e escalabilidade:

### 1. Camada de Rede (Networking)
* **VPC**: Rede isolada com CIDR `10.0.0.0/16`.
* **Subnets**: 
  * **Públicas**: Hospedam NAT Gateways e Load Balancers em duas zonas de disponibilidade (1a e 1b).
  * **Privadas**: Hospedam o banco de dados RDS e camadas lógicas, sem acesso direto pela internet.
* **Segurança**: VPC Flow Logs ativado para auditoria de tráfego armazenada no S3.

### 2. Banco de Dados (RDS)
* **Motor**: PostgreSQL (db.t3.micro).
* **Arquitetura**: 
  * **Master**: Instância principal para escrita (us-east-1a).
  * **Read Replica**: Instância para leitura (us-east-1b), garantindo performance e redundância.
* **Segurança**: Isolado em um `db_subnet_group` privado.

### 3. Microserviços e Processamento de Vídeo
* **Serverless**: Funções AWS Lambda (Node.js 18.x) integradas ao **AWS X-Ray** para rastreabilidade ativa.
* **Pipeline de Vídeo**:
  * Upload no bucket `uniplus-video-input-g5`.
  * Processamento automático via Lambda.
  * Armazenamento final no bucket `uniplus-video-output-g5`.
* **Microserviços**: Estrutura preparada para serviços de `Auth`, `Conteúdo` e `Acadêmico`.

### 4. Frontend (SPA)
* **Hospedagem S3**: Três portais estáticos configurados como site:
  * 🧑‍🎓 **Portal do Aluno**
  * 👨‍🏫 **Portal do Professor**
  * 📝 **Sistema de Matrícula**
* **Acesso**: Configurado com políticas de leitura pública para laboratório acadêmico.

---

## 📊 Monitoramento e Observabilidade

Implementamos uma camada de inteligência operacional:
* **CloudWatch Dashboards**: Painel executivo unificando métricas de CPU, conexões de banco e saúde dos serviços.
* **Alarmes**: Alertas automáticos via CloudWatch Alarms caso o consumo de recursos exceda 80%.
* **AWS X-Ray**: Rastreamento de latência e gargalos entre os microserviços e o banco de dados.

---

## 💰 Estratégia FinOps (Gestão de Custos)

* **AWS Budgets**: Limite de gastos configurado em **$50.00 USD/mês** com notificações de alerta.
* **Tags de Alocação**: Uso de `default_tags` em todos os recursos para rastreamento detalhado no AWS Cost Explorer.
* **Retenção de Logs**: Configurada para 7 dias, evitando custos desnecessários de armazenamento de longo prazo.

---

## 🛠️ Tecnologias Utilizadas

| Ferramenta | Uso |
| :--- | :--- |
| **Terraform** | IaC (Provisionamento) |
| **AWS Lambda** | Processamento Serverless |
| **Amazon RDS** | Banco de Dados Relacional |
| **Amazon S3** | Storage e Web Hosting |
| **CloudWatch** | Monitoramento e Logs |
| **AWS X-Ray** | Tracing de Microserviços |

---

## 🚀 Como Executar

1. **Requisitos**: Ter o Terraform instalado e as credenciais da AWS configuradas.
2. **Inicializar**: `terraform init`
3. **Validar**: `terraform validate`
4. **Planejar**: `terraform plan -out tfplan.binary`
5. **Aplicar**: `terraform apply tfplan.binary`

---

## 📐 Topologia da Solução

A infraestrutura foi desenhada seguindo o framework de **Well-Architected** da AWS, utilizando múltiplas Zonas de Disponibilidade (AZs) para garantir resiliência.

| Componente | Detalhe Técnico |
| :--- | :--- |
| **VPC** | 10.0.0.0/16 |
| **Zonas** | us-east-1a, us-east-1b |
| **Frontend** | S3 Static Website Hosting |
| **Database** | Multi-AZ RDS PostgreSQL (Master/Replica) |
| **Compute** | AWS Lambda (Event-driven) |

> **Aviso**: Este projeto utiliza a `LabRole` pré-configurada da AWS Academy para garantir compatibilidade com as permissões de laboratório.
