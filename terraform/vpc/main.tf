locals {
  name_prefix = var.app_env == "" ? var.account_name : "${var.account_name}-${var.app_env}"

  default_tags = merge(var.common_tags, {
    AccountName = var.account_name
    Environment = var.app_env
    ManagedBy   = "terraform"
    Stack       = "vpc"
  })

  public_subnets = {
    for i, cidr in var.public_subnet_cidrs : i => {
      cidr = cidr
      az   = var.azs[i]
    }
  }

  private_subnets = {
    for i, cidr in var.private_subnet_cidrs : i => {
      cidr = cidr
      az   = var.azs[i]
    }
  }

  database_subnets = {
    for i, cidr in var.database_subnet_cidrs : i => {
      cidr = cidr
      az   = var.azs[i]
    }
  }
}


resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# capture all vpc traffic for security auditing - CIS 3.9
resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = "/aws/vpc/${local.name_prefix}-flow-logs"
  retention_in_days = var.flow_log_retention_days
  kms_key_id        = var.flow_log_kms_key_arn != "" ? var.flow_log_kms_key_arn : null
  tags              = local.default_tags
}

data "aws_iam_policy_document" "flow_logs_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "flow_logs" {
  count              = var.enable_flow_logs ? 1 : 0
  name               = "${local.name_prefix}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume.json
  tags               = local.default_tags
}

data "aws_iam_policy_document" "flow_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = length(aws_cloudwatch_log_group.flow_logs) > 0 ? ["${aws_cloudwatch_log_group.flow_logs[0].arn}:*"] : ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  count  = var.enable_flow_logs ? 1 : 0
  name   = "${local.name_prefix}-vpc-flow-logs-policy"
  role   = aws_iam_role.flow_logs[0].id
  policy = data.aws_iam_policy_document.flow_logs.json
}

resource "aws_flow_log" "this" {
  count           = var.enable_flow_logs ? 1 : 0
  vpc_id          = aws_vpc.this.id
  traffic_type    = "ALL"
  iam_role_arn    = aws_iam_role.flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.flow_logs[0].arn

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-flow-log" })
}


resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-public-${each.value.az}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-private-${each.value.az}"
    Tier = "private"
  })
}

resource "aws_subnet" "database" {
  for_each = local.database_subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-database-${each.value.az}"
    Tier = "database"
  })
}

# NACLs are stateless so we need both directions per flow.
# ephemeral ports 1024-65535 are needed for TCP return traffic

# public subnets: https in from internet, ephemeral return ports out
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.public : s.id]

  # inbound https from internet
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  # inbound ephemeral return ports from nat gateway responses
  ingress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  # outbound https to internet via nat
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  # outbound ephemeral ports back to internet clients
  egress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-public-nacl" })
}

# private subnets: only accept traffic from within the VPC, outbound via NAT
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.private : s.id]

  # inbound from within the VPC (lambda, load balancers etc)
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 65535
  }
  # inbound ephemeral return from internet via nat
  ingress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  # outbound https for aws api calls through nat
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  # outbound postgres to db subnets
  egress {
    rule_no    = 200
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }
  # outbound ephemeral return within the VPC
  egress {
    rule_no    = 300
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-private-nacl" })
}

# db subnets: only postgres from private subnets, nothing else in or out
resource "aws_network_acl" "database" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for s in aws_subnet.database : s.id]

  # inbound postgres from private subnets only
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 5432
    to_port    = 5432
  }
  # outbound ephemeral return to private subnets
  egress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 1024
    to_port    = 65535
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-database-nacl" })
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = var.enable_nat_gateway ? (var.single_nat_gateway ? { 0 = 0 } : local.public_subnets) : {}

  domain = "vpc"

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-nat-eip-${each.key}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = aws_eip.nat

  allocation_id = each.value.id
  subnet_id     = var.single_nat_gateway ? values(aws_subnet.public)[0].id : aws_subnet.public[each.key].id

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-nat-${each.key}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[each.key].id
    }
  }

  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-private-rt-${each.value.az}"
    Tier = "private"
  })
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table" "database" {
  for_each = local.database_subnets

  vpc_id = aws_vpc.this.id

  # db subnets are completely isolated, no internet route
  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}-database-rt-${each.value.az}"
    Tier = "database"
  })
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[each.key].id
}
