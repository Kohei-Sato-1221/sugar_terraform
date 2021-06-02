provider "aws" {
	region = "ap-northeast-1"
}


# 実行時に上書き可能
# 例：
# terraform plan -var "sugar_instance_type=t3.nano"
variable "sugar_instance_type" {
	default = "t2.micro"
}

# local変数は実行時に上書き不可能
locals {
	sugar_tag = "sugar_tag_sample001"
}

# 外部データを参照できる
data "aws_ami" "recent_amazon_linux_2" {
	most_recent = true
	owners	    = ["amazon"]

	filter {
		name   = "name"
		values = ["amzn2-ami-hvm-2.0.????????-x86_64-gp2"]
	}

	filter {
		name   = "state"
		values = ["available"]
	}
}

resource "aws_security_group" "sugar_tf_sg" {
	name = "sugar-ec2"

	ingress {
	  to_port = 80
	  from_port = 80
	  protocol = "tcp"
	  cidr_blocks = [ "0.0.0.0/0" ]
	}

	egress {
	  to_port = 0
	  from_port = 0
	  protocol = "-1"
	  cidr_blocks = [ "0.0.0.0/0" ]
	}
}

resource "aws_instance" "sugar_tf_ec2" {
	ami		= data.aws_ami.recent_amazon_linux_2.image_id
	instance_type   = var.sugar_instance_type
	vpc_security_group_ids = [aws_security_group.sugar_tf_sg.id]
	
	tags = {
		Name = local.sugar_tag
	}
	
	user_data = <<EOF
		#!/bin/bash
		yum install -y httpd
		systemctl start httpd.service
EOF
}

# outputは実行結果後に特定の値を出力可能
output "instance_id" {
	value = aws_instance.sugar_tf_ec2.id
}
output "ami" {
	value = aws_instance.sugar_tf_ec2.ami
}
output "private_ip" {
	value = aws_instance.sugar_tf_ec2.private_ip
}
output "public_ip" {
	value = aws_instance.sugar_tf_ec2.public_ip
}

output "public_dns" {
	value = aws_instance.sugar_tf_ec2.public_dns
}