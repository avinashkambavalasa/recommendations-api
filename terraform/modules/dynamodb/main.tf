resource "aws_dynamodb_table" "this" {
  name                        = var.table_name
  billing_mode                = var.billing_mode
  read_capacity               = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity              = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  hash_key                    = var.hash_key
  range_key                   = var.range_key != "" ? var.range_key : null
  deletion_protection_enabled = var.deletion_protection
  table_class                 = var.table_class

  # Partition key attribute
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  # Sort key attribute (only when range_key is set)
  dynamic "attribute" {
    for_each = var.range_key != "" ? [1] : []
    content {
      name = var.range_key
      type = var.range_key_type
    }
  }

  # Extra attributes required by GSIs / LSIs
  dynamic "attribute" {
    for_each = var.additional_attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = try(global_secondary_index.value.range_key, null)
      projection_type = try(global_secondary_index.value.projection_type, "ALL")
      read_capacity   = var.billing_mode == "PROVISIONED" ? try(global_secondary_index.value.read_capacity, var.read_capacity) : null
      write_capacity  = var.billing_mode == "PROVISIONED" ? try(global_secondary_index.value.write_capacity, var.write_capacity) : null
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name            = local_secondary_index.value.name
      range_key       = local_secondary_index.value.range_key
      projection_type = try(local_secondary_index.value.projection_type, "ALL")
    }
  }

  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []
    content {
      enabled        = true
      attribute_name = var.ttl_attribute_name
    }
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  point_in_time_recovery {
    enabled = true
  }

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region_name = replica.value
    }
  }

  tags = merge(var.tags, {
    Name = var.table_name
  })
}
