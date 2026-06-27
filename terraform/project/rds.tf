# only spun up when sql_db is non-empty

resource "aws_db_subnet_group" "this" {
  count = local.create_rds ? 1 : 0

  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = var.db_subnet_ids

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-db-subnets" })
}

# ingress from source sg is handled inside modules/rds, add extra rules below

# egress from lambda to each db sg, skipped if lambda isnt in a vpc
resource "aws_security_group_rule" "lambda_to_db" {
  for_each = length(var.private_subnet_ids) > 0 ? var.sql_db : {}

  type                     = "egress"
  description              = "db egress to ${each.key} rds sg"
  from_port                = each.value.port
  to_port                  = each.value.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda[0].id
  source_security_group_id = module.rds[each.key].security_group_id
}

# dba/vpn access - leave ext_rds_sg_cidr_block empty to skip this
resource "aws_security_group_rule" "db_from_dba" {
  for_each = length(var.ext_rds_sg_cidr_block) > 0 ? var.sql_db : {}

  type              = "ingress"
  description       = "dba access from approved cidrs"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = "tcp"
  security_group_id = module.rds[each.key].security_group_id
  cidr_blocks       = var.ext_rds_sg_cidr_block
}

module "rds" {
  source   = "../modules/rds"
  for_each = var.sql_db

  app_name = var.app_name
  app_env  = var.app_env
  name     = each.key

  vpc_id                   = var.vpc_id
  source_security_group_id = length(var.private_subnet_ids) > 0 ? aws_security_group.lambda[0].id : null
  db_subnet_group_name     = aws_db_subnet_group.this[0].name

  engine_version             = each.value.engine_version
  instance_class             = each.value.node_type
  allocated_storage          = each.value.disk_size
  max_allocated_storage      = each.value.max_disk_size
  admin_user                 = each.value.admin_user
  port                       = each.value.port
  multi_az                   = each.value.multi_az
  deletion_protection        = each.value.deletion_protection
  apply_immediately          = each.value.apply_changes_immediately
  backup_retention_days      = each.value.backup_retention_days
  storage_type               = each.value.storage_type
  storage_throughput         = each.value.storage_throughput
  iops                       = each.value.iops
  monitoring_interval        = each.value.monitoring_interval
  auto_minor_version_upgrade = each.value.auto_minor_version_upgrade
  auto_major_version_upgrade = each.value.auto_major_version_upgrade
  read_replica               = each.value.read_replica
  read_replica_multi_az      = each.value.read_replica_multi_az
  log_min_duration_statement = each.value.log_min_duration_statement
  pg_force_ssl               = each.value.pg_force_ssl

  tags = merge(local.default_tags, { db_name = each.key })
}
