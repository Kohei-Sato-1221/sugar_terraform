provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_vpc" "sugar_vpc" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = {
        Name = "sugar_vpc"
    }
}

resource "aws_subnet" "sugar_public_0" {
    vpc_id = aws_vpc.sugar_vpc.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1a"
}

resource "aws_subnet" "sugar_public_1" {
    vpc_id = aws_vpc.sugar_vpc.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1c"
}

resource "aws_internet_gateway" "sugar_ig" {
    vpc_id = aws_vpc.sugar_vpc.id
}

resource "aws_route_table" "sugar_public" {
    vpc_id = aws_vpc.sugar_vpc.id
}

resource "aws_route" "sugar_public" {
    route_table_id = aws_route_table.sugar_public.id
    gateway_id = aws_internet_gateway.sugar_ig.id
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "sugar_public_0" {
    subnet_id = aws_subnet.sugar_public_0.id
    route_table_id = aws_route_table.sugar_public.id
}

resource "aws_route_table_association" "sugar_public_1" {
    subnet_id = aws_subnet.sugar_public_0.id
    route_table_id = aws_route_table.sugar_public.id
}

resource "aws_subnet" "sugar_private_0" {
    vpc_id = aws_vpc.sugar_vpc.id
    cidr_block = "10.0.65.0/24"
    availability_zone = "ap-northeast-1a"
    map_public_ip_on_launch = false
}

resource "aws_subnet" "sugar_private_1" {
    vpc_id = aws_vpc.sugar_vpc.id
    cidr_block = "10.0.66.0/24"
    availability_zone = "ap-northeast-1c"
    map_public_ip_on_launch = false
}

resource "aws_route_table" "sugar_private_0" {
    vpc_id = aws_vpc.sugar_vpc.id
}

resource "aws_route_table" "sugar_private_1" {
    vpc_id = aws_vpc.sugar_vpc.id
}

resource "aws_route" "sugar_private_0" {
    route_table_id = aws_route_table.sugar_private_0.id
    nat_gateway_id = aws_nat_gateway.sugar_ng_0.id
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "sugar_private_1" {
    route_table_id = aws_route_table.sugar_private_1.id
    nat_gateway_id = aws_nat_gateway.sugar_ng_1.id
    destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "sugar_private_0" {
    subnet_id = aws_subnet.sugar_private_0.id
    route_table_id = aws_route_table.sugar_private_0.id
}

resource "aws_route_table_association" "sugar_private_1" {
    subnet_id = aws_subnet.sugar_private_1.id
    route_table_id = aws_route_table.sugar_private_1.id
}

resource "aws_eip" "sugar_ng_eip_0" {
    vpc = true
    depends_on = [aws_internet_gateway.sugar_ig]
}

resource "aws_eip" "sugar_ng_eip_1" {
    vpc = true
    depends_on = [aws_internet_gateway.sugar_ig]
}

resource "aws_nat_gateway" "sugar_ng_0" {
    allocation_id = aws_eip.sugar_ng_eip_0.id
    subnet_id = aws_subnet.sugar_public_0.id
    depends_on = [aws_internet_gateway.sugar_ig]
}

resource "aws_nat_gateway" "sugar_ng_1" {
    allocation_id = aws_eip.sugar_ng_eip_1.id
    subnet_id = aws_subnet.sugar_public_1.id
    depends_on = [aws_internet_gateway.sugar_ig]
}

module "sugar_sg" {
    source = "./security_group"
    name = "sugar-sg"
    vpc_id = aws_vpc.sugar_vpc.id
    port = 80
    cidr_blocks = ["0.0.0.0/0"]
}