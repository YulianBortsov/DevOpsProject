resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "aws_db_subnet_group" "rds" {
  name       = "rds"
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}
resource "aws_security_group" "rds" {
  name_prefix = "rds"
  description = "Security group for RDS instance"
  vpc_id      = module.vpc.vpc_id

  # Allow traffic from EKS nodes security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  tags = local.tags
}
resource "aws_db_instance" "rds" {
  identifier             = lower(var.db_name)
  allocated_storage      = 5
  db_name                = var.db_name
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  username               = "app_user"
  password               = random_password.rds_password.result
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  tags                   = local.tags
}
resource "aws_secretsmanager_secret" "rds_credentials" {
  name        = "${local.name}/rds-credential"
  description = "RDS credentials for the application"
  tags        = local.tags
}
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    "password" = random_password.rds_password.result
    "host"     = aws_db_instance.rds.address
    "port"     = "5432"
    "dbname"   = aws_db_instance.rds.db_name
    "username" = aws_db_instance.rds.username
  })
}
