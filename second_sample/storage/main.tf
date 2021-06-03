provider "aws" {
    region = "ap-northeast-1"
}

# bucket for ALB
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

# bucket policy
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

/*
# プライベートバケット
resource "aws_s3_bucket" "private" {
    bucket = "private-sugar-bucket-1221"

    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}

resource "aws_s3_bucket_public_access_block" "private" {
    bucket = aws_s3_bucket.private.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
}


# パブリックバケット
resource "aws_s3_bucket" "public" {
    bucket = "public-sugar-bucket-1221"
    acl = "public-read"

    cors_rule {
        allowed_origins = [ "*" ]
        allowed_methods = [ "GET" ]
        allowed_headers = [ "*" ]
        max_age_seconds = 3000
    }
}
*/