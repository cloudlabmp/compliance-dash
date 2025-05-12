# VPC module for compliance dashboard

# Create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      "Name"                                      = "${var.environment}-${var.vpc_name}"
      "Environment"                               = var.environment
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    },
    var.tags
  )
}

# Create public subnets
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index % length(var.availability_zones)]
  map_public_ip_on_launch = true

  tags = merge(
    {
      "Name"                                      = "${var.environment}-${var.vpc_name}-public-${count.index + 1}"
      "Environment"                               = var.environment
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
    },
    var.tags
  )
}

# Create private subnets
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]

  tags = merge(
    {
      "Name"                                      = "${var.environment}-${var.vpc_name}-private-${count.index + 1}"
      "Environment"                               = var.environment
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/internal-elb"           = "1"
    },
    var.tags
  )
}

# Create internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      "Name"        = "${var.environment}-${var.vpc_name}-igw"
      "Environment" = var.environment
    },
    var.tags
  )
}

# Create elastic IP for NAT gateway
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"

  tags = merge(
    {
      "Name"        = "${var.environment}-${var.vpc_name}-nat-eip"
      "Environment" = var.environment
    },
    var.tags
  )
}

# Create NAT gateway
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    {
      "Name"        = "${var.environment}-${var.vpc_name}-nat"
      "Environment" = var.environment
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.main]
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      "Name"        = "${var.environment}-${var.vpc_name}-public-rt"
      "Environment" = var.environment
    },
    var.tags
  )
}

# Create private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      "Name"        = "${var.environment}-${var.vpc_name}-private-rt"
      "Environment" = var.environment
    },
    var.tags
  )
}

# Create public route
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# Create private route through NAT gateway if enabled
resource "aws_route" "private_nat_gateway" {
  count = var.enable_nat_gateway ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main[0].id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with private route table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnet_cidrs)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Create security group for EKS cluster
resource "aws_security_group" "eks_cluster" {
  name        = "${var.environment}-${var.vpc_name}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    {
      "Name"        = "${var.environment}-${var.vpc_name}-eks-cluster-sg"
      "Environment" = var.environment
    },
    var.tags
  )
}

# Allow all outbound traffic
resource "aws_security_group_rule" "cluster_egress" {
  security_group_id = aws_security_group.eks_cluster.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Allow inbound traffic from within the VPC
resource "aws_security_group_rule" "cluster_ingress_vpc" {
  security_group_id = aws_security_group.eks_cluster.id
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Allow all inbound traffic from within the VPC"
}

# Create security group for nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${var.environment}-${var.vpc_name}-eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  tags = merge(
    {
      "Name"        = "${var.environment}-${var.vpc_name}-eks-nodes-sg"
      "Environment" = var.environment
    },
    var.tags
  )
}

# Allow all outbound traffic from nodes
resource "aws_security_group_rule" "nodes_egress" {
  security_group_id = aws_security_group.eks_nodes.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Allow inbound traffic from nodes to nodes
resource "aws_security_group_rule" "nodes_ingress_self" {
  security_group_id        = aws_security_group.eks_nodes.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow all inbound traffic from nodes"
}

# Allow inbound traffic from cluster to nodes
resource "aws_security_group_rule" "nodes_ingress_cluster" {
  security_group_id        = aws_security_group.eks_nodes.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_cluster.id
  description              = "Allow all inbound traffic from cluster"
}

# Allow inbound traffic from nodes to cluster
resource "aws_security_group_rule" "cluster_ingress_nodes" {
  security_group_id        = aws_security_group.eks_cluster.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.eks_nodes.id
  description              = "Allow all inbound traffic from nodes"
}
