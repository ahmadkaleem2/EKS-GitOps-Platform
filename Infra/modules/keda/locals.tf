locals {

  helm_set = {
    "serviceAccount.annotations.\\eks\\.amazonaws\\.com\\/role-arn" = aws_iam_role.this.arn
    "serviceAccount.create" = "true",
    "serviceAccount.name"   = var.service_account_name

  }
}