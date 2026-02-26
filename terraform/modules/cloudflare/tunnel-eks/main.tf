terraform {
  required_version = ">= 1.5"
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# ============================================================================
# Tunnel
# ============================================================================

resource "random_id" "tunnel_secret" {
  byte_length = 32
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  account_id    = var.cloudflare_account_id
  name          = var.tunnel_name
  config_src    = "local"
  tunnel_secret = random_id.tunnel_secret.b64_std
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

# ============================================================================
# DNS CNAME records — one per exposed service
# ============================================================================

resource "cloudflare_dns_record" "services" {
  for_each = toset(var.services)

  zone_id = var.cloudflare_zone_id
  name    = each.key
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
  proxied = true
  ttl     = 1 # Auto (required when proxied)
}

# ============================================================================
# Store tunnel token in AWS SSM (for ESO on EKS to consume)
# ============================================================================

resource "aws_ssm_parameter" "tunnel_token" {
  name      = var.ssm_parameter_path
  type      = "SecureString"
  value     = data.cloudflare_zero_trust_tunnel_cloudflared_token.this.token
  overwrite = true
}
