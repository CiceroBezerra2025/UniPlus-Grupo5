resource "aws_ecs_cluster" "main_cluster" {
  name = "uniplus-cluster"
}

# Auth Service
resource "aws_ecs_task_definition" "auth_task" {
  family                   = "auth-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "auth-app"
    image = "sua-conta.dkr.ecr.us-east-1.amazonaws.com/auth-service:latest"
    portMappings = [{ containerPort = 8080, hostPort = 8080 }]
  }])
}

resource "aws_ecs_service" "auth_service" {
  name            = "auth-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.auth_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }
}

# Conteúdo Service
resource "aws_ecs_task_definition" "conteudo_task" {
  family                   = "conteudo-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "conteudo-app"
    image = "sua-conta.dkr.ecr.us-east-1.amazonaws.com/conteudo-service:latest"
    portMappings = [{ containerPort = 8081, hostPort = 8081 }]
  }])
}

resource "aws_ecs_service" "conteudo_service" {
  name            = "conteudo-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.conteudo_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }
}

# Académico Service
resource "aws_ecs_task_definition" "academico_task" {
  family                   = "academico-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([{
    name  = "academico-app"
    image = "sua-conta.dkr.ecr.us-east-1.amazonaws.com/academico-service:latest"
    portMappings = [{ containerPort = 8082, hostPort = 8082 }]
  }])
}

resource "aws_ecs_service" "academico_service" {
  name            = "academico-service"
  cluster         = aws_ecs_cluster.main_cluster.id
  task_definition = aws_ecs_task_definition.academico_task.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    assign_public_ip = false
  }
}