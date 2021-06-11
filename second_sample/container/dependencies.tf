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

module "sugar_http_sg" {
    source = "./security_group"
    name = "sugar-http-sg"
    vpc_id = aws_vpc.sugar_vpc.id
    port = 80
    cidr_blocks = ["0.0.0.0/0"]
}

module "sugar_https_sg" {
    source = "./security_group"
    name = "sugar-https-sg"
    vpc_id = aws_vpc.sugar_vpc.id
    port = 443
    cidr_blocks = ["0.0.0.0/0"]
}

module "sugar_http_redirect_sg" {
    source = "./security_group"
    name = "sugar-redirect-sg"
    vpc_id = aws_vpc.sugar_vpc.id
    port = 8080
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "sugar_lb" {
    name = "sugar-lb"
    load_balancer_type = "application"
    internal = false # インターネット向け or VPC内部向け
    idle_timeout = 60
    enable_deletion_protection = false

    subnets = [
        aws_subnet.sugar_public_0.id,
        aws_subnet.sugar_public_1.id,
    ]

    access_logs {
        bucket = aws_s3_bucket.sugar_alb_log.id
        enabled = true
    }

    security_groups = [
        module.sugar_http_sg.security_group_id,
        module.sugar_https_sg.security_group_id,
        module.sugar_http_redirect_sg.security_group_id,
    ]
}

resource "aws_lb_listener" "sugar_http" {
    load_balancer_arn = aws_lb.sugar_lb.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "This is http!!"
            status_code = "200"
        }
    }
}

resource "aws_lb_target_group" "sugar_tg" {
    name = "sugar-tg"
    vpc_id = aws_vpc.sugar_vpc.id
    target_type = "ip"
    port = 80
    protocol = "HTTP"
    deregistration_delay = 300

    health_check {
        path = "/"
        healthy_threshold = 5
        unhealthy_threshold = 2
        timeout = 5
        interval = 30
        matcher = 200
        port = "traffic-port"
        protocol = "HTTP"
    }

    depends_on = [aws_lb.sugar_lb]
}


resource "aws_lb_listener_rule" "sugar_rule" {
    listener_arn = aws_lb_listener.sugar_http.arn
    priority = 100
    
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.sugar_tg.arn
    }

    condition {
        path_pattern {
            values = ["*"]
        }
    }
}

resource "aws_s3_bucket" "sugar_alb_log" {
    bucket = "sugar-alb-log-1221"
    force_destroy = true # trueにすると中身があっても削除できる

    lifecycle_rule {
        enabled = true

        expiration {
            days = "180"
        }
    }
}

resource "aws_s3_bucket_policy" "sugar_alb_log" {
    bucket = aws_s3_bucket.sugar_alb_log.id
    policy = data.aws_iam_policy_document.sugar_alb_log.json
}

data "aws_iam_policy_document" "sugar_alb_log" {
    statement {
        effect = "Allow"
        actions = ["s3:PutObject"]
        resources = ["arn:aws:s3:::${aws_s3_bucket.sugar_alb_log.id}/*"]

        principals {
            type = "AWS"
            identifiers = ["582318560864"] # AWSが管理しているアカウント（リージョン毎に異なる）
        }
    }
}