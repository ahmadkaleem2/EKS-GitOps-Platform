locals {
  cluster_oidc_issuer_url   = replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")
}

resource "aws_iam_role" "albc" {

  name               = "albc-role-${data.terraform_remote_state.eks.outputs.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.cluster_oidc_issuer_url}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:aws-load-balancer-controller:aws-load-balancer-controller",

          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "albc" {                                                                                                       
  policy = file("${path.module}/custom_policies/load_balancer_controller.json")
  name = "Ahmad_EKS_aws_load_balancer_controller_policy"        
}



resource "aws_iam_role_policy_attachment" "albc" {
  role       = aws_iam_role.albc.name
  policy_arn = aws_iam_policy.albc.arn
}


resource "aws_iam_role" "external_dns" {

  name               = "external-dns-role-${data.terraform_remote_state.eks.outputs.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.cluster_oidc_issuer_url}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:external-dns:external-dns",

          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "external_dns" {                                                                                                       
  policy = file("${path.module}/custom_policies/external_dns.json")
  name = "Ahmad_EKS_external_dns_policy"        
}



resource "aws_iam_role_policy_attachment" "external_dns" {
  role       = aws_iam_role.external_dns.name
  policy_arn = aws_iam_policy.external_dns.arn
}




resource "aws_iam_role" "fluent_bit" {

  name               = "fluent-bit-role-${data.terraform_remote_state.eks.outputs.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.cluster_oidc_issuer_url}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:aws-for-fluent-bit:aws-for-fluent-bit",

          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "fluent_bit" {                                                                                                       
  policy = file("${path.module}/custom_policies/fluent-bit.json")
  name = "Ahmad_EKS_fluent_bit_policy"        
}



resource "aws_iam_role_policy_attachment" "fluent_bit" {
  role       = aws_iam_role.fluent_bit.name
  policy_arn = aws_iam_policy.fluent_bit.arn
}



resource "aws_iam_role" "karpenter" {

  name               = "karpenter-role-${data.terraform_remote_state.eks.outputs.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.cluster_oidc_issuer_url}"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:karpenter:karpenter",

          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "karpenter" {                                                                                                       
  policy = file("${path.module}/custom_policies/karpenter.json")
  name = "Ahmad_EKS_karpenter_policy"        
}



resource "aws_iam_role_policy_attachment" "karpenter" {
  role       = aws_iam_role.karpenter.name
  policy_arn = aws_iam_policy.karpenter.arn
}