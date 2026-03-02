# Gitleaks

Secret detection tool that scans Git repositories for hardcoded credentials.

## Why Gitleaks

Gitleaks scans commits and diffs for patterns matching API keys, passwords, tokens, and other secrets. It catches accidental credential leaks before they reach the remote repository. Chosen for its speed, low false-positive rate, and easy CI integration.

## Role in This Project

- **CI Gate**: Runs on every PR in GitHub Actions — blocks merge if secrets are detected
- **Full History Scan**: Can scan the entire Git history for previously committed secrets
- **Custom Rules**: Configurable via `.gitleaks.toml` for project-specific patterns
- **Pre-Commit**: Can run locally as a pre-commit hook for immediate feedback

## Related

- [GitHub Actions](github-actions.md) — Gitleaks runs as a CI pipeline step
- [Shift-Left Security](../concepts/shift-left.md) — Earliest security check in the pipeline
- [Supply Chain Security](../concepts/supply-chain-security.md) — Prevents credential leaks in source code
- [DevSecOps](../concepts/devsecops.md) — Automated secret detection at the code stage

## Docs

- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [Gitleaks Configuration](https://github.com/gitleaks/gitleaks#configuration)
