# Use existing ACM certificate (already issued)
data "aws_acm_certificate" "app" {
  domain      = var.application_domain
  statuses    = ["ISSUED"]
  most_recent = true
}
