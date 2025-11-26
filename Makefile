# ===============================================================
# Makefile for OBSB (Observability in a Box)
# Helm chart linting, packaging, cluster testing, and release.
# ===============================================================

CHART_NAME      := obsb
CHART_DIR       := charts/$(CHART_NAME)
DIST_DIR        := dist
KIND_CLUSTER    := obsb-kind
KIND_CONFIG     := kind-config.yaml

CHART_VERSION   := $(shell yq '.version' $(CHART_DIR)/Chart.yaml)
HELM_REPO_URL   ?= https://your-helm-repo.example.com/charts

# Default target
.PHONY: all
all: deps lint package

# ===============================================================
# Helm Dependency Management
# ===============================================================
.PHONY: deps
deps:
	@echo "🔄 Updating Helm dependencies..."
	helm dependency build $(CHART_DIR)

# ===============================================================
# Linting
# ===============================================================
.PHONY: lint
lint:
	@echo "🔍 Linting OBSB chart..."
	helm lint $(CHART_DIR)

.PHONY: lint-all
lint-all:
	@echo "🔍 Linting all charts..."
	helm lint charts/*

# ===============================================================
# Render Chart Templates
# ===============================================================
.PHONY: template
template:
	@echo "🧩 Rendering templates..."
	helm template $(CHART_NAME) $(CHART_DIR) > rendered.yaml
	@echo "📄 Output written to rendered.yaml"

.PHONY: template-values
template-values:
	@echo "🧩 Rendering templates with values.yaml..."
	helm template $(CHART_NAME) $(CHART_DIR) -f $(CHART_DIR)/values.yaml > rendered.yaml
	@echo "📄 Output written to rendered.yaml"

# ===============================================================
# Packaging
# ===============================================================
.PHONY: package
package: deps
	@echo "📦 Packaging Helm chart..."
	mkdir -p $(DIST_DIR)
	helm package $(CHART_DIR) --destination $(DIST_DIR)
	@echo "🎉 Chart packaged: $(DIST_DIR)"

.PHONY: version
version:
	@echo "📌 OBSB chart version: $(CHART_VERSION)"

# ===============================================================
# Install / Upgrade / Uninstall OBSB
# ===============================================================
.PHONY: install
install: deps
	@echo "🚀 Installing OBSB chart..."
	helm install $(CHART_NAME) $(CHART_DIR) -n obsb-core --create-namespace

.PHONY: upgrade
upgrade:
	@echo "⬆️ Upgrading OBSB chart..."
	helm upgrade $(CHART_NAME) $(CHART_DIR) -n obsb-core

.PHONY: uninstall
uninstall:
	@echo "🧽 Uninstalling OBSB..."
	helm uninstall $(CHART_NAME) -n obsb-core || true

# ===============================================================
# KIND CLUSTER MANAGEMENT
# ===============================================================
.PHONY: kind-up
kind-up:
	@echo "🌱 Checking for existing Kind cluster '$(KIND_CLUSTER)'..."
	@if kind get clusters | grep -q $(KIND_CLUSTER); then \
		echo "✔ Kind cluster '$(KIND_CLUSTER)' already exists."; \
	else \
		echo "🚀 Creating Kind cluster '$(KIND_CLUSTER)'..."; \
		kind create cluster --name $(KIND_CLUSTER) --config $(KIND_CONFIG); \
		echo "🎉 Kind cluster created!"; \
	fi
	@echo "⌛ Waiting for control plane node to be ready..."
	kubectl wait --for=condition=Ready node/$(KIND_CLUSTER)-control-plane --timeout=120s || true
	@echo "✔ Kind cluster is ready."

.PHONY: kind-down
kind-down:
	@echo "🗑️ Deleting Kind cluster '$(KIND_CLUSTER)'..."
	kind delete cluster --name $(KIND_CLUSTER)

.PHONY: kind-restart
kind-restart: kind-down kind-up

# ===============================================================
# Install OBSB into KIND for testing
# ===============================================================
.PHONY: kind-install
kind-install: kind-up
	@echo "🚀 Installing OBSB into Kind cluster..."
	helm install $(CHART_NAME) $(CHART_DIR) -n obsb-core --create-namespace

.PHONY: kind-upgrade
kind-upgrade:
	@echo "⬆️ Upgrading OBSB in Kind..."
	helm upgrade $(CHART_NAME) $(CHART_DIR) -n obsb-core

.PHONY: kind-uninstall
kind-uninstall:
	@echo "🧽 Uninstalling OBSB from Kind..."
	helm uninstall $(CHART_NAME) -n obsb-core || true

# ===============================================================
# Push to Helm repository (optional)
# ===============================================================
.PHONY: release
release: package
	@echo "🚀 Publishing OBSB chart to Helm repo: $(HELM_REPO_URL)"
	curl --fail -T $(DIST_DIR)/$(CHART_NAME)-$(CHART_VERSION).tgz $(HELM_REPO_URL)/
	@echo "🎉 Chart uploaded!"

# ===============================================================
# Cleanup
# ===============================================================
.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -rf $(DIST_DIR) rendered.yaml
