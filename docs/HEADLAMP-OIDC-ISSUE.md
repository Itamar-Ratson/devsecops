# Headlamp OIDC Authentication Issue

**Status:** Unresolved
**Date:** 2026-02-03
**Components:** Headlamp, Keycloak, OIDC

## Symptoms

1. User logs in to Headlamp at https://headlamp.localhost
2. Keycloak login page appears and accepts credentials (testuser/testuser)
3. After successful authentication, user briefly sees Headlamp UI
4. Within seconds, user gets "Lost connection to cluster" error
5. User is redirected back to login page
6. Cycle repeats indefinitely

## Error Messages

### Headlamp Logs
```
{"level":"error","cluster":"main","error":"refreshing token: getting refresh token: key not found","message":"failed to refresh token"}
```

### Keycloak Logs
```
type="REFRESH_TOKEN_ERROR", clientId="headlamp", error="invalid_token", reason="Invalid refresh token"
```

## Root Cause Analysis

The error `"getting refresh token: key not found"` indicates Headlamp cannot find a refresh token in its token storage after the initial OIDC authentication. This could mean:

1. **Keycloak is not returning a refresh token** in the token response
2. **Headlamp is not properly storing** the refresh token received
3. **The `offline_access` scope is not being granted** despite being requested

## Current Configuration

### Headlamp OIDC Settings (from secret `headlamp-oidc-secret`)
```yaml
OIDC_CLIENT_ID: headlamp
OIDC_ISSUER_URL: https://keycloak.localhost/realms/devsecops
OIDC_SCOPES: openid profile email groups offline_access
```

### Headlamp Deployment Args
```
-in-cluster
-plugins-dir=/headlamp/plugins
-oidc-client-id=$(OIDC_CLIENT_ID)
-oidc-client-secret=$(OIDC_CLIENT_SECRET)
-oidc-idp-issuer-url=$(OIDC_ISSUER_URL)
-oidc-scopes=$(OIDC_SCOPES)
-oidc-ca-file=/etc/ssl/certs/gateway-ca.crt
```

### Keycloak Client Configuration (headlamp)
```json
{
  "clientId": "headlamp",
  "enabled": true,
  "clientAuthenticatorType": "client-secret",
  "redirectUris": ["https://headlamp.localhost/*", "https://headlamp.localhost/oidc-callback"],
  "webOrigins": ["https://headlamp.localhost"],
  "standardFlowEnabled": true,
  "implicitFlowEnabled": false,
  "directAccessGrantsEnabled": false,
  "publicClient": false,
  "protocol": "openid-connect",
  "fullScopeAllowed": true
}
```

### Keycloak Realm Configuration
- `offline_access` scope is defined in `clientScopes`
- `offline_access` is in `defaultOptionalClientScopes` (clients must explicitly request it)
- Test user `testuser` has `realmRoles: ["default-roles-devsecops"]`

### Keycloak Import Strategy
- Using `JAVA_OPTS_APPEND` with migration parameters (not `--import-realm`)
- Strategy: `OVERWRITE_EXISTING` (confirmed in logs)

## Fixes Attempted

### 1. Added offline_access to Headlamp scopes
**Commit:** `c831171 fix(headlamp): add offline_access scope for refresh tokens`
**Result:** Failed - Keycloak returned "offline tokens not allowed"

### 2. Removed offline_access scope
**Commit:** `f8bd946 fix(headlamp): remove offline_access scope (not allowed by Keycloak)`
**Result:** Failed - no refresh token returned

### 3. Restored offline_access and added user roles
**Commits:**
- `7292302 fix(headlamp): restore offline_access scope for OIDC refresh tokens`
- `9e7e522 fix(keycloak): assign default realm roles to testuser for offline_access`
**Result:** Failed - still getting "Code not valid" errors

### 4. Added offline_access client scope definition
**Commit:** `b2751c6 fix(keycloak): add offline_access client scope definition to realm config`
**Result:** Failed - same issue

### 5. Fixed Keycloak import strategy
**Commits:**
- `13e92a2 fix(keycloak): use JAVA_OPTS_APPEND for import strategy`
- `8c52a6d fix(keycloak): use full migration params instead of --import-realm for OVERWRITE_EXISTING`
**Result:** Import strategy now works (OVERWRITE_EXISTING confirmed), but OIDC still fails

### 6. Added network policy for Headlamp → Keycloak
**Commit:** `ee99289 add ingress rule to keycloak`
**Result:** Network connectivity confirmed working

## Files Involved

- `helm/headlamp/templates/vault-secrets.yaml` - OIDC configuration
- `helm/headlamp/values.yaml` - Headlamp Helm values
- `helm/keycloak/templates/realm-config.yaml` - Keycloak realm JSON
- `helm/keycloak/values-keycloak.yaml` - Keycloak Helm values
- `helm/keycloak/templates/networkpolicy.yaml` - Cilium network policy

## Possible Next Steps

1. **Check if Keycloak actually returns refresh_token**
   - Use `curl` to manually perform OIDC token exchange
   - Verify the token response includes `refresh_token` field

2. **Add offline_access to Headlamp client's defaultClientScopes**
   - Currently relies on realm defaults
   - Explicitly add to client config in realm JSON

3. **Check Headlamp's token storage mechanism**
   - May be an issue with how Headlamp stores tokens (session vs cookie)
   - Check if there are additional Headlamp configuration options

4. **Try without offline_access**
   - Use regular refresh tokens instead of offline tokens
   - May need different scope configuration

5. **Debug OIDC flow manually**
   ```bash
   # Get authorization code
   # Exchange code for tokens
   # Inspect token response for refresh_token
   ```

6. **Check Headlamp GitHub issues**
   - Search for similar OIDC/refresh token issues
   - May be a known bug or configuration requirement

## Root Cause Identified

**Multiple issues discovered:**

### Issue 1: Kubernetes API Server Not Configured for OIDC
The Kubernetes API server needs OIDC configuration to verify tokens from Keycloak:
```yaml
apiServer:
  extraArgs:
    oidc-issuer-url: "https://keycloak.localhost/realms/devsecops"
    oidc-client-id: "headlamp"
    oidc-username-claim: "preferred_username"
    oidc-groups-claim: "groups"
    oidc-ca-file: "/path/to/ca.crt"
```

**Chicken-and-egg problem:** The CA certificate is generated by cert-manager AFTER the cluster starts,
but the API server needs it AT startup. Solution: Pre-generate CA before cluster creation.

### Issue 2: Headlamp Impersonation Bug
[GitHub Issue #4198](https://github.com/kubernetes-sigs/headlamp/issues/4198) - Headlamp v0.38.0+
doesn't properly add Impersonate-User headers when making API calls in in-cluster mode with OIDC.

### Issue 3: Headlamp Refresh Token Bug
**This is a known Headlamp bug** affecting versions v0.28.1 through v0.39.0+.

### Related GitHub Issues:
- [#3143](https://github.com/kubernetes-sigs/headlamp/issues/3143) - "OIDC token refresh is not working" (supposedly fixed in v0.32.0)
- [#3961](https://github.com/kubernetes-sigs/headlamp/issues/3961) - Multi-cluster refresh token issue
- [#4134](https://github.com/kubernetes-sigs/headlamp/issues/4134) - "Can't get OIDC to Azure EntraID refresh token"

The fix (PR #3478) was merged for v0.32.0, but the issue persists in later versions including v0.39.0.

## Workaround Applied

Extended Keycloak token lifespans to reduce frequency of refresh token issues:
```json
"accessTokenLifespan": 3600,        // 1 hour (was 5 minutes)
"ssoSessionIdleTimeout": 86400,     // 24 hours (was 30 minutes)
"ssoSessionMaxLifespan": 86400      // 24 hours (was 10 hours)
```

This doesn't fix the underlying bug but gives users longer sessions before hitting the refresh issue.

## Environment

- Keycloak: 24.0 (Quarkus-based)
- Headlamp: v0.39.0
- Kubernetes: KinD cluster
- CNI: Cilium with Gateway API
- TLS: cert-manager with self-signed CA
