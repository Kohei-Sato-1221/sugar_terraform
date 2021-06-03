provider "aws" {
    region = "ap-northeast-1"
}

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