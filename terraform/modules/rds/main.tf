locals {
  name_prefix = "${var.app_name}-${var.app_env}-${var.name}"
  max_storage = var.max_allocated_storage != null ? var.max_allocated_storage : max(var.allocated_storage + 10, 30)
  # non-prod envs dont need a final snapshot, just clutters the console
  skip_snapshot = !contains(["stg", "prod", "perf", "qa"], var.app_env)
}

# sg is defined here so extra rules dont accidentally end up mixed in the project layer.
# optional rules (dba cidrs, bastion) go in project/rds.tf

resource "aws_security_group" "this" {
  name        = "${local.name_prefix}-rds-sg"
  description = "rds sg for ${local.name_prefix} - no egress, rds doesnt call out"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${local.name_prefix}-rds-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# only the source sg can reach the db port, no hardcoded port numbers
resource "aws_security_group_rule" "ingress_source_sg" {
  count = var.source_security_group_id != null ? 1 : 0

  type                     = "ingress"
  description              = "db access from source sg (${var.name})"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = var.source_security_group_id
}


resource "aws_db_parameter_group" "this" {
  name   = "${local.name_prefix}-pg"
  family = "postgres${split(".", var.engine_version)[0]}"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = tostring(var.log_min_duration_statement)
    apply_method = "immediate"
  }

  parameter {
    name  = "log_min_error_statement"
    value = "ERROR"
  }

  parameter {
    name         = "rds.force_ssl"
    value        = tostring(var.pg_force_ssl)
    apply_method = "immediate"
  }

  lifecycle {
    # minor upgrades change the family name and cause a replacement we dont want
    ignore_changes = [parameter]
  }

  tags = merge(var.tags, { Name = "${local.name_prefix}-pg" })
}

resource "random_password" "admin" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${local.name_prefix}-db-secret"
  recovery_window_in_days = 7
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.admin_user
    password = random_password.admin.result
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = var.port
    dbname   = aws_db_instance.this.db_name
  })
}

# Primary DB Instance

resource "aws_db_instance" "this" {
  identifier            = "${local.name_prefix}-rds"
  engine                = "postgres"
  engine_version        = var.engine_version
  instance_class        = var.instance_class
  allocated_storage     = var.allocated_storage
  max_allocated_storage = local.max_storage
  storage_type          = var.storage_type
  storage_throughput    = var.storage_type == "gp3" ? var.storage_throughput : null
  iops                  = contains(["gp3", "io1", "io2"], var.storage_type) && var.iops > 0 ? var.iops : null
  storage_encrypted     = true

  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  username = var.admin_user
  password = random_password.admin.result
  port     = var.port

  publicly_accessible = false
  multi_az            = var.multi_az
  deletion_protection = var.deletion_protection

  backup_retention_period   = var.backup_retention_days
  apply_immediately         = var.apply_immediately
  skip_final_snapshot       = local.skip_snapshot
  final_snapshot_identifier = local.skip_snapshot ? null : "${local.name_prefix}-final-snapshot"

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.auto_major_version_upgrade

  # app connects via IAM token, not the password. password stays in secrets manager for manual access
  iam_database_authentication_enabled = true

  performance_insights_enabled = true
  monitoring_interval          = var.monitoring_interval

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = merge(var.tags, { Name = "${local.name_prefix}-rds" })

  lifecycle {
    ignore_changes = [password]
  }
}


resource "aws_db_instance" "read_replica" {
  count = var.read_replica ? 1 : 0

  identifier          = "${local.name_prefix}-rds-replica"
  replicate_source_db = aws_db_instance.this.identifier
  instance_class      = var.instance_class
  storage_type        = var.storage_type
  storage_encrypted   = true

  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this.name

  publicly_accessible = false
  multi_az            = var.read_replica_multi_az
  deletion_protection = var.deletion_protection

  skip_final_snapshot       = local.skip_snapshot
  final_snapshot_identifier = local.skip_snapshot ? null : "${local.name_prefix}-rds-replica-final-snapshot"
  apply_immediately         = var.apply_immediately

  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.auto_major_version_upgrade

  iam_database_authentication_enabled = true

  performance_insights_enabled = true

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = merge(var.tags, { Name = "${local.name_prefix}-rds-replica" })

  lifecycle {
    ignore_changes = [password]
  }
}
