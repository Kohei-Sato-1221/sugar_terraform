provider "aws" {
    region = "ap-northeast-1"
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

resource "aws_lb_listener" "sugar_https" {
    load_balancer_arn = aws_lb.sugar_lb.arn
    port = "443"
    protocol = "HTTPS"
    certificate_arn = aws_acm_certificate.sugar_acm.arn
    ssl_policy = "ELBSecurityPolicy-2016-08"

    default_action {
        type = "fixed-response"

        fixed_response {
            content_type = "text/plain"
            message_body = "This is http!!"
            status_code = "200"
        }
    }
}

resource "aws_lb_listener" "sugar_redirect_to_https" {
    load_balancer_arn = aws_lb.sugar_lb.arn
    port = "8080"
    protocol = "HTTPS"
    certificate_arn = aws_acm_certificate.sugar_acm.arn
    ssl_policy = "ELBSecurityPolicy-2016-08"

    default_action {
        type = "redirect"

        redirect {
            port = "443"
            protocol = "HTTPS"
            status_code = "HTTP_301"
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

resource "aws_lb_listener_rule" "sugar_lb_listener_rule" {
    listener_arn = aws_lb_listener.sugar_https.arn
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

/*
# https://mel.onl/onamae-domain-aws-route-53/
# host zoneが変更になると面倒なのでTF管轄外にする
resource "aws_route53_zone" "sugar_zone" {
    name = "kohekohe.net"
}

# ここで表示されたNSをお名前.comの「他のネームサーバーを使う」に登録すること
output "name_server" {
    value = {for v in aws_route53_zone.sugar_zone.name_servers: v => v}
}
*/

data "aws_route53_zone" "sugar_zone" {
    # name = "kohekohe.net"
    name = "kohekohe1221.site"
}

resource "aws_route53_record" "sugar_record" {
    zone_id = data.aws_route53_zone.sugar_zone.id
    # zone_id = aws_route53_zone.sugar_zone.id
    name = data.aws_route53_zone.sugar_zone.name
    # name = aws_route53_zone.sugar_zone.name
    type = "A"

    alias {
        name = aws_lb.sugar_lb.dns_name
        zone_id = aws_lb.sugar_lb.zone_id
        evaluate_target_health = true
    }
}

resource "aws_acm_certificate" "sugar_acm" {
    # domain_name = aws_route53_zone.sugar_zone.name
    domain_name = data.aws_route53_zone.sugar_zone.name
    subject_alternative_names = []
    validation_method = "DNS"

    lifecycle {
        create_before_destroy = true
    }
}

output "alb_dns_name" {
    value = aws_lb.sugar_lb.dns_name
}

## DNS検証用のレコード
resource "aws_route53_record" "sugar_certificate" {
    for_each = {
        for dvo in aws_acm_certificate.sugar_acm.domain_validation_options : dvo.domain_name => {
            name = dvo.resource_record_name
            type = dvo.resource_record_type
            record = dvo.resource_record_value
        }
    }

    name = each.value.name
    type = each.value.type
    records = [each.value.record]
    zone_id = data.aws_route53_zone.sugar_zone.id
    # zone_id = aws_route53_zone.sugar_zone.id
    ttl = 60
}

## 検証の待機
resource "aws_acm_certificate_validation" "sugar_acm_validation" {
    certificate_arn = aws_acm_certificate.sugar_acm.arn
    validation_record_fqdns = [for record in aws_route53_record.sugar_certificate : record.fqdn]
}