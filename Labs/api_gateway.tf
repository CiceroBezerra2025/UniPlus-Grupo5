# 1. Definição do API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "main" {
  name          = "uniplus-api"
  protocol_type = "HTTP"
  cors_configuration {
    allow_origins = ["*"] # Em produção, substitua pelos domínios do CloudFront
    allow_methods = ["GET", "POST", "PUT", "DELETE"]
    allow_headers = ["Content-Type", "Authorization"]
  }
}

# 2. Stage (Ambiente)
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# 3. VPC Link (Para conectar o API Gateway à sua VPC privada)
resource "aws_apigatewayv2_vpc_link" "ecs_link" {
  name               = "uniplus-vpc-link"
  security_group_ids = [aws_security_group.ecs_tasks_sg.id]
  subnet_ids         = aws_subnet.private[*].id
}

# 4. Integração com o Load Balancer (Exemplo para o Auth Service)
resource "aws_apigatewayv2_integration" "auth_integration" {
  api_id           = aws_apigatewayv2_api.main.id
  integration_type = "HTTP_PROXY"
  integration_method = "ANY"
  connection_type  = "VPC_LINK"
  connection_id    = aws_apigatewayv2_vpc_link.ecs_link.id
  
  # Aqui usamos o Listener ARN do seu Load Balancer Interno
  integration_uri  = aws_lb_listener.internal_http.arn 
}

# 5. Definição das Rotas
# Rota para Autenticação
resource "aws_apigatewayv2_route" "auth_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /auth/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}"
}

# Rota para Conteúdo
resource "aws_apigatewayv2_route" "conteudo_route" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /conteudo/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.auth_integration.id}" 
  # Nota: Em um cenário real, você teria integrações diferentes se cada serviço tiver um LB ou porta diferente.
}