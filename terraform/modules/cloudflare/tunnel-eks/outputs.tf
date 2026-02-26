output "tunnel_id" {
  description = "CloudFlare Tunnel ID"
  value       = cloudflare_zero_trust_tunnel_cloudflared.this.id
}

output "tunnel_cname" {
  description = "CloudFlare Tunnel CNAME target"
  value       = "${cloudflare_zero_trust_tunnel_cloudflared.this.id}.cfargotunnel.com"
}

output "ssm_parameter_arn" {
  description = "ARN of the SSM parameter storing the tunnel token"
  value       = aws_ssm_parameter.tunnel_token.arn
}
