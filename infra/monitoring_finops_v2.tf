# --- GRUPOS DE LOGS PARA MICROSERVIÇOS ---
# Criando logs individuais para facilitar a depuração e o custo por serviço
resource "aws_cloudwatch_log_group" "microservices_logs" {
  for_each = toset(["auth", "conteudo", "academico"])
  
  name              = "/aws/lambda/uniplus-${each.key}-service"
  retention_in_days = 7 # FinOps: retenção curta para economizar armazenamento
  
  tags = {
    Microservice = each.key
    CostCenter   = "Microservices-Log"
  }
}

# --- ALARMES DE ERROS (CloudWatch Alarms) ---
# Alarme que dispara se qualquer microserviço apresentar erros frequentes
resource "aws_cloudwatch_metric_alarm" "microservice_errors" {
  for_each = aws_cloudwatch_log_group.microservices_logs

  alarm_name          = "Error-Alarm-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "60"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "Monitora falhas críticas no microserviço ${each.key}"
  
  dimensions = {
    FunctionName = "uniplus-${each.key}-service"
  }
}

# --- MONITORAMENTO DE PERFORMANCE (X-Ray) ---
# Configuração para que os microserviços enviem rastros para o X-Ray
# Isso ajuda a identificar qual serviço está lento em uma chamada encadeada
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

  # --- ESTRATÉGIA DE TAGS PARA FINOPS ---
  tags = {
    Name         = "UniPlus-${each.key}"
    Service      = each.key
    Environment  = "Production"
    Project      = "UniPlus-G5"
    ManagedBy    = "Terraform"
  }
}

# --- FILTROS DE MÉTRICAS PARA FINOPS ---
# Criar uma métrica personalizada no CloudWatch para contar acessos ao portal
# Útil para entender o custo por usuário ativo (FinOps Unit Metric)
resource "aws_cloudwatch_log_metric_filter" "portal_access_count" {
  name           = "PortalAccessCount"
  pattern        = "[..., status=200, size, url=/portal*]"
  log_group_name = "/aws/lambda/uniplus-auth-service"

  metric_transformation {
    name      = "AccessCount"
    namespace = "UniPlus/Traffic"
    value     = "1"
  }
}