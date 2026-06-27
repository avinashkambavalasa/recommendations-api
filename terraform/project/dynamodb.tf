# Flatten the two-level dynamo_db map into { "<namespace>-<table-key>" => config }
locals {
  dynamo_tables = merge([
    for ns, tables in var.dynamo_db :
    { for tkey, cfg in tables : "${ns}-${tkey}" => cfg }
  ]...)
}

module "dynamodb_table" {
  source   = "../modules/dynamodb"
  for_each = local.dynamo_tables

  table_name               = "${local.name_prefix}-${each.key}"
  hash_key                 = each.value.hash_key
  hash_key_type            = try(each.value.hash_key_type, "S")
  range_key                = try(each.value.range_key, "")
  range_key_type           = try(each.value.range_key_type, "S")
  billing_mode             = try(each.value.billing_mode, "PAY_PER_REQUEST")
  read_capacity            = try(each.value.read_capacity, 5)
  write_capacity           = try(each.value.write_capacity, 5)
  table_class              = try(each.value.table_class, "STANDARD")
  ttl_enabled              = try(each.value.ttl_enabled, false)
  ttl_attribute_name       = try(each.value.ttl_attribute_name, "ttl")
  deletion_protection      = try(each.value.deletion_protection, true)
  kms_key_arn              = null
  additional_attributes    = try(each.value.additional_attributes, [])
  global_secondary_indexes = try(each.value.global_secondary_indexes, [])
  local_secondary_indexes  = try(each.value.local_secondary_indexes, [])
  replica_regions          = try(each.value.replica_regions, [])
  tags                     = local.default_tags
}
