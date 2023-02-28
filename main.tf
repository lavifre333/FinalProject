terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
}

# Create the VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "final-project"
  }
}

# Creates the first public subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public Subnet 1"
  }
}

# Creates the second public subnet
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Public Subnet 2"
  }
}

# Create the first private subnet
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.103.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private Subnet 1"
  }
}

# Create the second private subnet
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.104.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "Private Subnet 2"
  }
}

# Create the internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ProjectIG"
  }
}

# Create the route table for both of the public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "PublicRT"
  }
}

# Connecting Public RT to IG
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Associate the public subnets with the route tables
resource "aws_route_table_association" "public_subnet_association_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

# Associate the public subnets with the route tables
resource "aws_route_table_association" "public_subnet_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# Create the route table for the first private subnet
resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "PrivateRT1"
  }
}

# Associate the first private subnet with the route table
resource "aws_route_table_association" "private_subnet_association_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}

# Create the route table for the second private subnet
resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.main.id
    tags = {
    Name = "PrivateRT2"
  }
}

# Associate the second private subnet with the route table
resource "aws_route_table_association" "private_subnet_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}

# Create the routes for the private route tables
resource "aws_route" "private_route_1" {
  route_table_id         = aws_route_table.private_route_table_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
}

resource "aws_route" "private_route_2" {
  route_table_id         = aws_route_table.private_route_table_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_2.id
}

# Create the NAT gateways
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_eip_1.id
  subnet_id     = aws_subnet.private_subnet_1.id
  tags = {
    Name = "PrivateNGT1"
  }
}

resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_eip_2.id
  subnet_id     = aws_subnet.private_subnet_2.id
  tags = {
    Name = "PrivateNGT2"
  }
}

# Create the Elastic IPs for the NAT gateways
resource "aws_eip" "nat_eip_1" {
  vpc = true
}

resource "aws_eip" "nat_eip_2" {
  vpc = true
}

####################################################################################
# Create aPOstgreSQL RDS
####################################################################################

# Set subnet group for the RDS
 resource "aws_db_subnet_group" "statuspage_db_subnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]

  tags = {
    Name = "status-page DB subnet group"
  }
}

# Set Postgres RDS
 resource "aws_db_instance" "status_page_db" {
  allocated_storage    = 10
  db_name              = "StatusPageDB"
  engine               = "postgres"
  engine_version       = "14"
  db_subnet_group_name =  aws_db_subnet_group.statuspage_db_subnet_group.id
  multi_az            = true
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  skip_final_snapshot  = true
}

####################################################################################
# Create redis elsastic cache
####################################################################################

resource "aws_elasticache_subnet_group" "status_page_redis_subnet_group" {
  name       = "status-page-redis-subnet-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  tags = {
    Name = "Status-Page-redis-cache-subnet-group"
  }
}

resource "aws_elasticache_replication_group" "status-page-redis-cache-db" {
  replication_group_id       = "status-page-redis-cache-cluster"
  description                = "radis elastic cache for status page app"
  engine                     = "redis"
  engine_version             = "4.0.10"
  subnet_group_name          = aws_elasticache_subnet_group.status_page_redis_subnet_group.id
  node_type                  = "cache.t2.small"
  port                       = 6379
  multi_az_enabled           = true
  automatic_failover_enabled = true

  num_node_groups         = 2
  replicas_per_node_group = 1

   tags = {
    Name = "Status-Page-redis-cache-cluster"
  }
}

####################################################################################
# Create CloudFrount
####################################################################################

resource "aws_cloudfront_distribution" "status-apge_cloudfront" {
  origin {
    domain_name = "testlb-3725147.us-east-1.elb.amazonaws.com"
    origin_id = "TestLB-3725147.us-east-1.elb.amazonaws.com"

    custom_origin_config {
      http_port = "80"
      https_port = "443"
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress = true
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "TestLB-3725147.us-east-1.elb.amazonaws.com"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    ssl_support_method = "sni-only"
  }
}