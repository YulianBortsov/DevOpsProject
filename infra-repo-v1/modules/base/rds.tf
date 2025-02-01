resource "random_password" "rds_password" {
  count = var.enable_rds ? 1 : 0
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
resource "aws_db_subnet_group" "rds" {
  count = var.enable_rds ? 1 : 0
  name       = "rds"
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}
resource "aws_security_group" "rds" {
  count = var.enable_rds ? 1 : 0
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
  count = var.enable_rds ? 1 : 0
  identifier             = lower(var.db_name)
  allocated_storage      = 5
  db_name                = var.db_name
  engine                 = "postgres"
  engine_version         = "16.3"
  instance_class         = "db.t3.micro"
  username               = "app_user"
  password               = random_password.rds_password[0].result
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.rds[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]
  publicly_accessible    = false
  tags                   = local.tags
}
resource "aws_secretsmanager_secret" "rds_credentials" {
  count       = var.enable_rds ? 1 : 0
  name        = "${local.name}/rds-credentials12345"
  description = "RDS credentials for the application"
  tags        = local.tags
}
resource "aws_secretsmanager_secret_version" "rds_credentials" {
  count        = var.enable_rds ? 1 : 0
  secret_id = aws_secretsmanager_secret.rds_credentials[0].id
  secret_string = jsonencode({
    "password" = random_password.rds_password[0].result
    "host"     = aws_db_instance.rds[0].address
    "port"     = "5432"
    "dbname"   = aws_db_instance.rds[0].db_name
    "username" = aws_db_instance.rds[0].username
  })
}
