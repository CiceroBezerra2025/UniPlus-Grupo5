# --- GRUPOS DE LOGS PARA MICROSERVIÇOS ---
# Criando logs individuais com retenção curta para FinOps (economia de storage)
resource "aws_cloudwatch_log_group" "microservices_logs" {
  for_each = toset(["auth", "conteudo", "academico"])
  
  name              = "/aws/lambda/uniplus-${each.key}-service"
  retention_in_days = 7 
  
  tags = {
    Microservice = each.key
    CostCenter   = "Microservices-Log"
    Project      = "UniPlus-G5"
  }
}

# --- MONITORAMENTO DE PERFORMANCE E RASTREIO (X-Ray) ---
# Configuração das Lambdas com rastreio ativo para identificar gargalos
resource "aws_lambda_function" "microservices" {
  for_each = toset(["auth", "conteudo", "academico"])

  function_name = "uniplus-${each.key}-service"
  role          = "arn:aws:iam::047118612495:role/LabRole" 
  handler       = "index.handler"
  runtime       = "nodejs18.x" 
  filename      = "lambda_function.zip"

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name         = "UniPlus-${each.key}"
    Service      = each.key
    Environment  = "Production"
    Project      = "UniPlus-G5"
  }
}

# --- ALARMES DE ERROS (CloudWatch Alarms) ---
# Alarme individual por microserviço para deteção rápida de falhas
resource "aws_cloudwatch_metric_alarm" "microservice_errors" {
  for_each = aws_lambda_function.microservices

  alarm_name          = "Error-Alarm-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0" # Dispara com qualquer erro
  alarm_description   = "Monitora falhas críticas no microserviço ${each.key}"
  
  dimensions = {
    FunctionName = each.value.function_name
  }
}

# --- FILTROS DE MÉTRICAS PARA FINOPS (CORREÇÃO DA SINTAXE) ---
# Criar uma métrica para contar acessos bem-sucedidos ao portal (Unit Metric)
resource "aws_cloudwatch_log_metric_filter" "portal_access_count" {
  name           = "PortalAccessCount"
  
  # Correção: Sintaxe simplificada para busca de texto em logs
  # Procura pela string "GET /portal" que indica um acesso ao frontend
  pattern        = "\"GET /portal\"" 

  # Correção: Referência direta ao recurso para garantir ordem de criação
  log_group_name = aws_cloudwatch_log_group.microservices_logs["auth"].name

  metric_transformation {
    name      = "AccessCount"
    namespace = "UniPlus/Traffic"
    value     = "1"
    default_value = 0 # Importante para FinOps para garantir que a métrica exista
  }
}