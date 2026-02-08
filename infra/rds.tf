resource "aws_db_subnet_group" "db_grp" {
  name       = "uniplus-db-group"
  subnet_ids = [aws_subnet.private_subnet_1a.id, aws_subnet.private_subnet_1b.id]
}

resource "aws_db_instance" "master" {
  identifier           = "uniplus-db-master"
  engine               = "postgres"
  instance_class       = "db.t3.micro"
  allocated_storage     = 20
  db_name              = "uniplusdb"
  username             = var.db_username
  password             = var.db_password
  db_subnet_group_name = aws_db_subnet_group.db_grp.name
  skip_final_snapshot  = true
  availability_zone    = "us-east-1a"
  backup_retention_period = 7
}

resource "aws_db_instance" "replica" {
  identifier           = "uniplus-db-replica"
  replicate_source_db  = aws_db_instance.master.identifier
  instance_class       = "db.t3.micro"
  availability_zone    = "us-east-1b"
  skip_final_snapshot  = true
}