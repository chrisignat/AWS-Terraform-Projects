# SECURITY GROUP ΓΙΑ ΤΗ ΒΑΣΗ ΔΕΔΟΜΕΝΩΝ

resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow PostgreSQL traffic ONLY from Web Servers"
  vpc_id      = aws_vpc.main.id

  # Inbound Rule
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # Outbound Rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Project-1-RDS-SG" }
}

# RDS SUBNET GROUP

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "project-1-rds-subnet-group"
  subnet_ids = [aws_subnet.isolated[0].id, aws_subnet.isolated[1].id]

  tags = { Name = "Project-1-RDS-Subnet-Group" }
}

# AMAZON RDS POSTGRESQL INSTANCE (MULTI-AZ)

# Random_password generation
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secret for Secret Manager
resource "aws_secretsmanager_secret" "db_secret" {
  name        = "production-db-credentials"
  description = "RDS Production Database Credentials"
}

# Store the secret password
resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password.result
  })
}

resource "aws_db_instance" "postgres" {
  identifier             = "project-3-postgres-db"
  allocated_storage      = 20
  max_allocated_storage  = 100
  db_name                = "myappdb"
  engine                 = "postgres"
  engine_version         = "18.4" 
  instance_class         = "db.t3.micro"
  
  username               = "dbadmin"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false

  multi_az               = true
  backup_retention_period = 7

  tags = { Name = "Project-1-MultiAZ-RDS" }
}

# RDS READ REPLICAS (Σε AZ-A και AZ-B)

resource "aws_db_instance" "postgres_read_replicas" {
  count                  = length(var.availability_zones)
  identifier             = "project-1-postgres-replica-${count.index + 1}"
  
  replicate_source_db    = aws_db_instance.postgres.identifier 
  
  instance_class         = "db.t3.micro"
  apply_immediately      = true
  publicly_accessible    = false
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  
  availability_zone      = var.availability_zones[count.index]

  tags = { 
    Name = "Project-1-RDS-ReadReplica-${count.index == 0 ? "A" : "B"}" 
  }

  depends_on = [
    aws_db_instance.postgres
  ]
}