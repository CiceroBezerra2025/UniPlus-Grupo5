# Cluster ECS
resource "aws_ecs_cluster" "main" {
  name = "uniplus-cluster-g5"
}

# Definição das Tarefas com as páginas de validação solicitadas
resource "aws_ecs_task_definition" "apps" {
  for_each                 = toset(["auth", "conteudo", "academico"])
  family                   = "uniplus-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = each.key
    image = "nginx:alpine"
    portMappings = [{ containerPort = 80, hostPort = 80 }]
    command = [
      "/bin/sh",
      "-c",
      "echo '<h1>Container Technologies Uniplus - Microserviço ${each.key}</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"
    ]
  }])
}

# Serviços rodando nas subnets privadas (segurança)
resource "aws_ecs_service" "svc" {
  for_each        = toset(["auth", "conteudo", "academico"])
  name            = "${each.key}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.apps[each.key].arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1b.id]
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tgs[each.key].arn
    container_name   = each.key
    container_port   = 80
  }
}

# Auto Scaling (CPU > 70%)
resource "aws_appautoscaling_target" "scale_target" {
  for_each           = toset(["auth", "conteudo", "academico"])
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.svc[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu_policy" {
  for_each           = toset(["auth", "conteudo", "academico"])
  name               = "scale-cpu-${each.key}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.scale_target[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.scale_target[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.scale_target[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    target_value = 70.0
  }
}