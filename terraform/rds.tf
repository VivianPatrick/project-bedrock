# ─── Subnet Group ─────────────────────────────────────────────────────────────

resource "aws_db_subnet_group" "rds" {
  name       = "bedrock-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name    = "bedrock-rds-subnet-group"
    Project = var.project_tag
  }
}

# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "rds" {
  name        = "bedrock-rds-sg"
  description = "Allow DB traffic from EKS nodes only"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "MySQL from EKS nodes"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  ingress {
    description     = "PostgreSQL from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "bedrock-rds-sg"
    Project = var.project_tag
  }
}

# ─── MySQL (Catalog Service) ──────────────────────────────────────────────────

resource "aws_db_instance" "mysql" {
  identifier        = "bedrock-mysql"
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "catalog"
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot    = true
  multi_az               = false
  publicly_accessible    = false

  tags = {
    Name    = "bedrock-mysql"
    Project = var.project_tag
  }
}

# ─── PostgreSQL (Orders Service) ──────────────────────────────────────────────

resource "aws_db_instance" "postgres" {
  identifier        = "bedrock-postgres"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = "orders"
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  multi_az            = false
  publicly_accessible = false

  tags = {
    Name    = "bedrock-postgres"
    Project = var.project_tag
  }
}

# ─── Secrets Manager (Store DB credentials securely) ─────────────────────────

resource "aws_secretsmanager_secret" "db_creds" {
  name                    = "bedrock/db-credentials"
  recovery_window_in_days = 0

  tags = {
    Name    = "bedrock-db-credentials"
    Project = var.project_tag
  }
}

resource "aws_secretsmanager_secret_version" "db_creds" {
  secret_id = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode({
    mysql_host     = aws_db_instance.mysql.address
    mysql_port     = 3306
    mysql_db       = "catalog"
    mysql_username = "admin"
    mysql_password = var.db_password
    pg_host        = aws_db_instance.postgres.address
    pg_port        = 5432
    pg_db          = "orders"
    pg_username    = "admin"
    pg_password    = var.db_password
  })
}