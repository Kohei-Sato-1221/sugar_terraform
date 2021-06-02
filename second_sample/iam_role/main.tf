variable "name" {}
variable "policy" {}
variable "identifier" {}

resource "aws_iam_role" "sugar_default" {
    name               = var.name
    assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
    statement {
      actions = ["sts:AssumeRole"]

      principals {
        type        = "Service"
        identifiers = [var.identifier]
      }
    }
}

resource "aws_iam_policy" "sugar_default" {
    name   = var.name
    policy = var.policy
}

resource "aws_iam_role_policy_attachment" "sugar_default" {
    role       = aws_iam_role.sugar_default.name
    policy_arn = aws_iam_policy.sugar_default.arn
}

output "iam_role_arn" {
    value = aws_iam_role.sugar_default.arn
}
output "iam_role_name" {
    value = aws_iam_role.sugar_default.name
}