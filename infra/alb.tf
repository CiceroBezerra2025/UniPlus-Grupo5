# Security Group para o ALB
resource "aws_security_group" "alb_sg" {
  name   = "uniplus-alb-sg"
  vpc_id = aws_vpc.minha_vpc.id
  ingress { from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# SG das Tasks (Só aceita tráfego do ALB)
resource "aws_security_group" "ecs_tasks_sg" {
  name   = "uniplus-tasks-sg"
  vpc_id = aws_vpc.minha_vpc.id
  ingress { from_port = 80; to_port = 80; protocol = "tcp"; security_groups = [aws_security_group.alb_sg.id] }
  egress  { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

# ALB Público
resource "aws_lb" "main" {
  name               = "uniplus-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1b.id]
}

resource "aws_lb_target_group" "tgs" {
  for_each    = toset(["auth", "conteudo", "academico"])
  name        = "tg-uniplus-${each.key}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.minha_vpc.id
  target_type = "ip"
  health_check { path = "/" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"
  default_action { type = "fixed-response"; fixed_response { content_type = "text/plain"; message_body = "Uniplus Root"; status_code = "200" } }
}

# Regras de Path-Based Routing
resource "aws_lb_listener_rule" "rules" {
  for_each     = toset(["auth", "conteudo", "academico"])
  listener_arn = aws_lb_listener.http.arn
  action { type = "forward"; target_group_arn = aws_lb_target_group.tgs[each.key].arn }
  condition { path_pattern { values = ["/${each.key}*"] } }
}