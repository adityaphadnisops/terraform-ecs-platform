resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name}-vpc" })
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0
  domain = "vpc"
  tags   = merge(var.tags, { Name = "${var.name}-nat-eip-${count.index}" })
}
resource "aws_nat_gateway" "this" {
  count         = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.public_subnets)) : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = merge(var.tags, { Name = "${var.name}-nat-gw-${count.index}" })
  depends_on    = [aws_internet_gateway.this]
}
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnets[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  tags                    = merge(var.tags, { Name = "${var.name}-public-${element(var.availability_zones, count.index)}" })
}
resource "aws_subnet" "private_ecs" {
  count             = length(var.private_ecs_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_ecs_subnets[count.index]
  availability_zone = element(var.availability_zones, count.index)
  tags              = merge(var.tags, { Name = "${var.name}-private-ecs-${element(var.availability_zones, count.index)}" })
}
resource "aws_subnet" "private_db" {
  count             = length(var.private_db_subnets)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_subnets[count.index]
  availability_zone = element(var.availability_zones, count.index)
  tags              = merge(var.tags, { Name = "${var.name}-private-db-${element(var.availability_zones, count.index)}" })
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table" "private_ecs" {
  count  = length(var.private_ecs_subnets)
  vpc_id = aws_vpc.this.id
  dynamic "route" {
    for_each = var.enable_nat_gateway ? (var.single_nat_gateway ? [0] : range(length(var.private_ecs_subnets))) : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[route.value].id
    }
  }
  tags = merge(var.tags, { Name = "${var.name}-private-ecs-rt-${count.index}" })
}
resource "aws_route_table_association" "private_ecs" {
  count          = length(aws_subnet.private_ecs)
  subnet_id      = aws_subnet.private_ecs[count.index].id
  route_table_id = aws_route_table.private_ecs[count.index].id
}
resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_ecs[count.index].id
}
