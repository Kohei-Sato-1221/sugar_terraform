provider "aws" {
    region = "ap-northeast-1"
}

resource "aws_lb" "sugar_lb" {
    name = "sugar-lb"
    load_balancer_type = "application"
    internal = false # インターネット向け or VPC内部向け
    idle_timeout = 60
    enable_deletion_protection = true

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

output "alb_dns_name" {
    value = aws_lb.sugar_lb.dns_name
}