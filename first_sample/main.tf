provider "aws" {
	region = "ap-northeast-1"
}

# 実行時に上書き可能
# terraform apply -var 'env=prod'
# terraform apply -var 'env=dev'
variable "env" {}

module "dev_server" {
	source = "./http_server"
	env = var.env
}

output "public_dns" {
  value = module.dev_server.public_dns
}
