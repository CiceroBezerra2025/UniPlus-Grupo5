# 1. Grupo de Subnets para o RDS (utiliza as subnets privadas criadas no vpc.tf)
resource "aws_db_subnet_group" "uniplus_db_group" {
  name       = "uniplus-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "Uniplus DB Subnet Group" }
}

# 2. Grupo de Segurança para o Banco de Dados
resource "aws_security_group" "rds_sg" {
  name        = "uniplus-rds-sg"
  description = "Permite acesso dos servicos ECS ao RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432 # Porta padrão PostgreSQL (use 3306 para MySQL)
    to_port         = 5432
    protocol        = "tcp"
    # Apenas o Security Group do ECS pode acessar o Banco
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Instância Master (Escrita e Leitura) - AZ 1
resource "aws_db_instance" "master" {
  identifier           = "uniplus-db-master"
  engine               = "postgres"
  engine_version       = "15.3"
  instance_class       = "db.t3.micro" # Ajuste conforme necessário
  allocated_storage     = 20
  storage_type         = "gp3"
  
  db_name              = "uniplusdb"
  username             = var.db_username
  password             = var.db_password # Use Secrets Manager em prod!
  
  db_subnet_group_name = aws_db_subnet_group.uniplus_db_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  availability_zone    = "us-east-1a"
  skip_final_snapshot  = true
  multi_az             = false # A réplica será criada separadamente abaixo

  backup_retention_period = 7
}

# 4. Instância de Réplica (Apenas Leitura) - AZ 2
resource "aws_db_instance" "replica" {
  identifier           = "uniplus-db-replica"
  replicate_source_db  = aws_db_instance.master.identifier
  instance_class       = "db.t3.micro"
  
  availability_zone    = "us-east-1b"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  # A réplica não precisa de db_name, user ou password (herda do master)
}