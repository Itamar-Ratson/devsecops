# Cloudflare Tunnel + Access

Secure external ingress and identity-aware access control without exposing ports.

## Why Cloudflare Tunnel

Cloudflare Tunnel creates outbound-only connections from the cluster to Cloudflare's edge, eliminating the need to open inbound ports or manage public IPs. Cloudflare Access adds identity-aware authentication in front of exposed services. Chosen for zero-inbound-port security and integration with Cloudflare's global edge network.

## Role in This Project

- **Cloudflare Tunnel (cloudflared)**: Runs as a pod, creating encrypted tunnels to Cloudflare's edge for external access to services
- **Cloudflare Access**: Adds identity-based authentication (email, IdP) before traffic reaches the cluster
- **DNS Management**: Terraform manages Cloudflare DNS records pointing to tunnels
- **Multi-Target**: Separate tunnel configurations for KinD and EKS

## Related

- [Gateway API](gateway-api.md) — Internal routing after traffic enters via tunnel
- [Tailscale](tailscale.md) — Alternative connectivity approach for private/mesh access
- [Zero Trust](../concepts/zero-trust.md) — No open inbound ports

## Docs

- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [Cloudflare Access Documentation](https://developers.cloudflare.com/cloudflare-one/policies/access/)
