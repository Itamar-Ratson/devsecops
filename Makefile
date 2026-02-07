# Terraform DevSecOps Makefile
# Targets for testing, security scanning, and infrastructure management

.PHONY: help test scan fmt validate setup-dnsmasq remove-dnsmasq clean

# Default target
help:
	@echo "Terraform DevSecOps Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  test            - Run Terraform tests for all modules"
	@echo "  scan            - Run Terrascan security scans on all modules"
	@echo "  fmt             - Format all Terraform files"
	@echo "  validate        - Validate all Terraform modules"
	@echo "  setup-dnsmasq   - Set up dnsmasq for *.localhost DNS resolution"
	@echo "  remove-dnsmasq  - Remove dnsmasq configuration"
	@echo "  clean           - Clean Terraform cache files"
	@echo ""

# Run Terraform tests for all modules
test:
	@echo "Running Terraform tests..."
	@for module in terraform/modules/*/; do \
		module_name=$$(basename $$module); \
		if [ "$$module_name" = "talos-cluster" ] || [ "$$module_name" = "argocd-bootstrap" ]; then \
			echo "Skipping $$module (requires integration environment)..."; \
			continue; \
		fi; \
		echo "Testing $$module..."; \
		(cd $$module && terraform init -upgrade && terraform test) || exit 1; \
	done
	@echo "✓ Unit tests passed!"
	@echo "Note: talos-cluster and argocd-bootstrap require integration testing with actual infrastructure"

# Run Terrascan security scans
scan:
	@echo "Running Terrascan security scans..."
	@terrascan scan -i terraform -d terraform/modules/libvirt-network || true
	@terrascan scan -i terraform -d terraform/modules/vault-vm || true
	@terrascan scan -i terraform -d terraform/modules/vault-config || true
	@terrascan scan -i terraform -d terraform/modules/talos-cluster || true
	@terrascan scan -i terraform -d terraform/modules/argocd-bootstrap || true
	@echo "✓ Security scans complete!"

# Format all Terraform files
fmt:
	@echo "Formatting Terraform files..."
	@terraform fmt -recursive terraform/
	@echo "✓ Formatting complete!"

# Validate all modules
validate:
	@echo "Validating Terraform modules..."
	@for module in terraform/modules/*/; do \
		echo "Validating $$module..."; \
		(cd $$module && terraform init -upgrade && terraform validate) || exit 1; \
	done
	@echo "✓ All modules valid!"

# Set up dnsmasq for *.localhost DNS resolution
setup-dnsmasq:
	@echo "Setting up dnsmasq (requires sudo)..."
	@echo ""
	@echo "This will:"
	@echo "  - Install dnsmasq"
	@echo "  - Configure wildcard: *.localhost → 192.168.100.200"
	@echo "  - Restart dnsmasq service"
	@echo ""
	@read -p "Continue? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		sudo apt-get install -y dnsmasq; \
		echo "address=/localhost/192.168.100.200" | sudo tee /etc/dnsmasq.d/k8s-local.conf; \
		sudo systemctl restart dnsmasq; \
		echo "✓ dnsmasq configured!"; \
		echo "Test: ping argocd.localhost (should resolve to 192.168.100.200)"; \
	else \
		echo "Cancelled."; \
	fi

# Remove dnsmasq configuration
remove-dnsmasq:
	@echo "Removing dnsmasq configuration..."
	@sudo rm -f /etc/dnsmasq.d/k8s-local.conf
	@sudo systemctl restart dnsmasq
	@echo "✓ dnsmasq configuration removed"

# Clean Terraform cache files
clean:
	@echo "Cleaning Terraform cache files..."
	@find terraform -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find terraform -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	@find terraform -type f -name "*.tfstate*" -delete 2>/dev/null || true
	@find terraform -type f -name "*.tfplan" -delete 2>/dev/null || true
	@echo "✓ Cache cleaned!"
