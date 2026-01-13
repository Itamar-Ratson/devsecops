# OWASP Juice Shop - Security Hardened Build
# Uses official image as base with distroless runtime for minimal attack surface

ARG JUICE_SHOP_VERSION=v19.1.1
FROM bkimminich/juice-shop:${JUICE_SHOP_VERSION} AS base

# Security hardening stage - distroless runtime
FROM gcr.io/distroless/nodejs22-debian12:nonroot

# Copy application from official image
COPY --from=base --chown=65532:65532 /juice-shop /juice-shop

WORKDIR /juice-shop

# Container metadata (OCI Image Spec)
# Re-declare ARG to make it available in this stage
ARG JUICE_SHOP_VERSION=v19.1.1
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.opencontainers.image.title="OWASP Juice Shop (Secure Build)" \
      org.opencontainers.image.description="Security-hardened build for secure-k8s project" \
      org.opencontainers.image.source="https://github.com/Itamar-Ratson/secure-k8s" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.base.name="bkimminich/juice-shop:${JUICE_SHOP_VERSION}"

# Run as non-root user (UID 65532 = nonroot in distroless)
USER 65532

EXPOSE 3000

CMD ["/juice-shop/build/app.js"]
