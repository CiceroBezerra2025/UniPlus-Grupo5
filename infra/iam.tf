# Nota: Recursos de criação de Role foram removidos/comentados 
# porque o utilizador não tem permissão iam:CreateRole no laboratório.
# O projeto agora utiliza a "LabRole" pré-configurada nos recursos do ECS e Lambda.

/*
resource "aws_iam_role" "ecs_execution_role" {
  name = "uniplus-ecs-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17", Statement = [{
      Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}
...
*/