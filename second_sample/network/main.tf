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

resource "aws_subnet" "sugar_public" {
    vpc_id = aws_vpc.sugar_vpc.id
    cidr_block = "10.0.0.0/24"
    map_public_ip_on_launch = true
    availability_zone = "ap-northeast-1a"
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

resource "aws_route_table_association" "sugar_public" {
    subnet_id = aws_subnet.sugar_public.id
    route_table_id = aws_route_table.sugar_public.id
}

resource "aws_subnet" "sugar_private" {
    vpc_id = aws_vpc.sugar_vpc.id
    cidr_block = "10.0.64.0/24"
    availability_zone = "ap-northeast-1a"
    map_public_ip_on_launch = false
}

resource "aws_route_table" "sugar_private" {
    vpc_id = aws_vpc.sugar_vpc.id
}

resource "aws_route_table_association" "sugar_private" {
    subnet_id = aws_subnet.sugar_private.id
    route_table_id = aws_route_table.sugar_private.id
}

resource "aws_eip" "sugar_ng_eip" {
    vpc = true
    depends_on = [aws_internet_gateway.sugar_ig]
}

resource "aws_nat_gateway" "sugar_ng" {
    allocation_id = aws_eip.sugar_ng_eip.id
    subnet_id = aws_subnet.sugar_public.id
    depends_on = [aws_internet_gateway.sugar_ig]
}

resource "aws_route" "sugar_private" {
    route_table_id = aws_route_table.sugar_private.id
    nat_gateway_id = aws_nat_gateway.sugar_ng.id
    destination_cidr_block = "0.0.0.0/0"
}
