# ======================================================================
# OBSB Makefile — Stable & Production-Ready for Kind + Helm
# ======================================================================

KIND_CLUSTER_NAME := obsb-kind
KIND_CONFIG := kind-config.yaml
NAMESPACE := obsb-core

# ----------------------------------------------------------------------
# KIND: CREATE CLUSTER
# ----------------------------------------------------------------------
kind-up:
	@echo "🌱 Checking if Kind cluster '$(KIND_CLUSTER_NAME)' already exists..."
	@if kind get clusters | grep -q "$(KIND_CLUSTER_NAME)"; then \
		echo "✔ Kind cluster '$(KIND_CLUSTER_NAME)' already exists."; \
		exit 0; \
	fi

	@echo "🚀 Creating Kind cluster '$(KIND_CLUSTER_NAME)'..."
	kind create cluster --name $(KIND_CLUSTER_NAME) --config $(KIND_CONFIG)

	@echo "⌛ Waiting for control-plane node to be Ready..."
	kubectl wait --for=condition=Ready node/$(KIND_CLUSTER_NAME)-control-plane --timeout=180s || true

	@echo "🛠 Applying OpenSearch sysctl vm.max_map_count fix to all Kind nodes..."
	@for node in $$(kind get nodes --name $(KIND_CLUSTER_NAME)); do \
		echo "📌 Setting vm.max_map_count inside $$node"; \
		docker exec $$node sysctl -w vm.max_map_count=262144 || true; \
	done

	@echo "🔐 Copying Docker Hub auth into containerd on all nodes..."
	@if [ -f $$HOME/.docker/config.json ]; then \
		for node in $$(kind get nodes --name $(KIND_CLUSTER_NAME)); do \
			echo "📌 Installing Docker auth into $$node"; \
			docker exec $$node mkdir -p /etc/containerd/certs.d/registry-1.docker.io || true; \
			docker cp $$HOME/.docker/config.json $$node:/etc/containerd/certs.d/registry-1.docker.io/config.json || true; \
		done; \
	else \
		echo "⚠️ WARNING: No ~/.docker/config.json found. You may hit Docker Hub rate limits."; \
	fi

	@echo "📥 Pre-loading Docker images into Kind cluster..."
	@docker pull busybox:latest 2>/dev/null || true
	@kind load docker-image busybox:latest --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull bitnami/postgresql:latest 2>/dev/null || true
	@kind load docker-image bitnami/postgresql:latest --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull zabbix/zabbix-agent:ubuntu-6.0.0 2>/dev/null || true
	@kind load docker-image zabbix/zabbix-agent:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull zabbix/zabbix-server-pgsql:ubuntu-6.0.0 2>/dev/null || true
	@kind load docker-image zabbix/zabbix-server-pgsql:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull zabbix/zabbix-web-apache-pgsql:ubuntu-6.0.0 2>/dev/null || true
	@kind load docker-image zabbix/zabbix-web-apache-pgsql:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull zabbix/zabbix-proxy-sqlite3:ubuntu-6.0.0 2>/dev/null || true
	@kind load docker-image zabbix/zabbix-proxy-sqlite3:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull opensearchproject/opensearch:2.19.4 2>/dev/null || true
	@kind load docker-image opensearchproject/opensearch:2.19.4 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull opensearchproject/opensearch-dashboards:2.19.4 2>/dev/null || true
	@kind load docker-image opensearchproject/opensearch-dashboards:2.19.4 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull opensearchproject/logstash-oss-with-opensearch-output-plugin:7.16.3 2>/dev/null || true
	@kind load docker-image opensearchproject/logstash-oss-with-opensearch-output-plugin:7.16.3 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true

	@echo "✔ Kind cluster '$(KIND_CLUSTER_NAME)' is ready!"

# ----------------------------------------------------------------------
# KIND: DESTROY + RESTART CLUSTER
# ----------------------------------------------------------------------
kind-down:
	@echo "🔥 Deleting Kind cluster '$(KIND_CLUSTER_NAME)'..."
	kind delete cluster --name $(KIND_CLUSTER_NAME)
	@echo "✔ Cluster deleted."

kind-restart: kind-down kind-up
	@echo "♻️ Kind cluster restarted."

# ----------------------------------------------------------------------
# OBSB DEPLOYMENT
# ----------------------------------------------------------------------
kind-install:
	@echo "📦 Ensuring namespace '$(NAMESPACE)' exists..."
	kubectl get ns $(NAMESPACE) || kubectl create ns $(NAMESPACE)

	@echo "📥 Pre-loading Docker images into Kind cluster (this may take a few minutes)..."
	@docker pull busybox:latest 2>/dev/null || true
	@kind load docker-image busybox:latest --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull bitnami/postgresql:latest 2>/dev/null || true
	@kind load docker-image bitnami/postgresql:latest --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull zabbix/zabbix-agent:ubuntu-6.0.0 2>/dev/null || true
	@kind load docker-image zabbix/zabbix-agent:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull zabbix/zabbix-server-pgsql:ubuntu-6.0.0 2>/dev/null || true
	@kind load docker-image zabbix/zabbix-server-pgsql:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull zabbix/zabbix-web-apache-pgsql:ubuntu-6.0.0 2>/dev/null || true
	@kind load docker-image zabbix/zabbix-web-apache-pgsql:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull zabbix/zabbix-proxy-sqlite3:ubuntu-6.0.0 2>/dev/null || true
	@kind load docker-image zabbix/zabbix-proxy-sqlite3:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull opensearchproject/opensearch:2.19.4 2>/dev/null || true
	@kind load docker-image opensearchproject/opensearch:2.19.4 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull opensearchproject/opensearch-dashboards:2.19.4 2>/dev/null || true
	@kind load docker-image opensearchproject/opensearch-dashboards:2.19.4 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@docker pull opensearchproject/logstash-oss-with-opensearch-output-plugin:7.16.3 2>/dev/null || true
	@kind load docker-image opensearchproject/logstash-oss-with-opensearch-output-plugin:7.16.3 --name $(KIND_CLUSTER_NAME) 2>/dev/null || true
	@echo "✔ Images loaded"

	@echo "🔐 Creating Docker Hub pull secret..."
	@if [ -f $$HOME/.docker/config.json ]; then \
		kubectl create secret generic dockerhub-secret \
			--from-file=.dockerconfigjson=$$HOME/.docker/config.json \
			--type=kubernetes.io/dockerconfigjson \
			-n $(NAMESPACE) --dry-run=client -o yaml | kubectl apply -f -; \
		echo "✔ Docker Hub secret created"; \
	else \
		echo "⚠️ WARNING: No ~/.docker/config.json found. Skipping pull secret."; \
	fi

	@echo "🚀 Deploying OBSB Helm chart..."
	helm upgrade --install obsb charts/obsb -n $(NAMESPACE)

	@echo "⌛ Watching pods..."
	kubectl get pods -n $(NAMESPACE) -w

kind-upgrade:
	@echo "⬆️ Upgrading OBSB in Kind..."
	helm upgrade obsb charts/obsb -n $(NAMESPACE)

kind-load-images:
	@echo "📥 Pre-loading Docker images into Kind cluster..."
	@echo "⏳ Pulling busybox:latest..."
	@docker pull busybox:latest || true
	@kind load docker-image busybox:latest --name $(KIND_CLUSTER_NAME) || true
	@echo "⏳ Pulling bitnami/postgresql:latest..."
	@docker pull bitnami/postgresql:latest || true
	@echo "⏳ Loading bitnami/postgresql:latest into Kind..."
	@kind load docker-image bitnami/postgresql:latest --name $(KIND_CLUSTER_NAME) || true
	@echo "⏳ Pulling zabbix/zabbix-agent:ubuntu-6.0.0..."
	@docker pull zabbix/zabbix-agent:ubuntu-6.0.0 || true
	@echo "⏳ Loading zabbix/zabbix-agent:ubuntu-6.0.0 into Kind..."
	@kind load docker-image zabbix/zabbix-agent:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) || true
	@echo "⏳ Pulling zabbix/zabbix-server-pgsql:ubuntu-6.0.0..."
	@docker pull zabbix/zabbix-server-pgsql:ubuntu-6.0.0 || true
	@kind load docker-image zabbix/zabbix-server-pgsql:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) || true
	@echo "⏳ Pulling zabbix/zabbix-web-apache-pgsql:ubuntu-6.0.0..."
	@docker pull zabbix/zabbix-web-apache-pgsql:ubuntu-6.0.0 || true
	@kind load docker-image zabbix/zabbix-web-apache-pgsql:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) || true
	@echo "⏳ Pulling zabbix/zabbix-proxy-sqlite3:ubuntu-6.0.0..."
	@docker pull zabbix/zabbix-proxy-sqlite3:ubuntu-6.0.0 || true
	@kind load docker-image zabbix/zabbix-proxy-sqlite3:ubuntu-6.0.0 --name $(KIND_CLUSTER_NAME) || true
	@echo "⏳ Pulling opensearchproject/opensearch:2.19.4..."
	@docker pull opensearchproject/opensearch:2.19.4 || true
	@kind load docker-image opensearchproject/opensearch:2.19.4 --name $(KIND_CLUSTER_NAME) || true
	@echo "⏳ Pulling opensearchproject/opensearch-dashboards:2.19.4..."
	@docker pull opensearchproject/opensearch-dashboards:2.19.4 || true
	@kind load docker-image opensearchproject/opensearch-dashboards:2.19.4 --name $(KIND_CLUSTER_NAME) || true
	@echo "⏳ Pulling opensearchproject/logstash-oss-with-opensearch-output-plugin:7.16.3..."
	@docker pull opensearchproject/logstash-oss-with-opensearch-output-plugin:7.16.3 || true
	@kind load docker-image opensearchproject/logstash-oss-with-opensearch-output-plugin:7.16.3 --name $(KIND_CLUSTER_NAME) || true
	@echo "✔ Images loaded into Kind cluster"

# ----------------------------------------------------------------------
# HELM UTILITIES
# ----------------------------------------------------------------------
lint:
	@echo "🔍 Linting Helm chart..."
	helm lint charts/obsb

package:
	@echo "📦 Packaging chart..."
	helm package charts/obsb -d dist

install-deps:
	@echo "📦 Updating Helm dependencies..."
	helm dependency update charts/obsb

template:
	@echo "📄 Rendering Helm templates..."
	helm template obsb charts/obsb -n $(NAMESPACE)

# ----------------------------------------------------------------------
# OBSB UTILITIES
# ----------------------------------------------------------------------
logs:
	kubectl logs -n $(NAMESPACE) -l app=obsb --tail=200 -f

pods:
	kubectl get pods -n $(NAMESPACE) -o wide

describe:
	kubectl describe pods -n $(NAMESPACE)

reset:
	@echo "🧹 Removing all resources in $(NAMESPACE)..."
	kubectl delete all -n $(NAMESPACE) --all || true

# ----------------------------------------------------------------------
# ACCESS SERVICES
# ----------------------------------------------------------------------
access-all:
	@echo "🌐 Opening all service endpoints..."
	@echo "   Zabbix:              http://localhost:8080 (Admin / zabbix)"
	@echo "   OpenSearch API:      https://localhost:9200 (admin / Zx9@gZXWJwYSVvKp7!)"
	@echo "   OpenSearch Dashboards: http://localhost:5601 (admin / Zx9@gZXWJwYSVvKp7!)"
	@echo ""
	@echo "Press Ctrl+C to stop all port forwards"
	@kubectl port-forward -n $(NAMESPACE) svc/obsb-zabbix-zabbix-web 8080:80 & \
	kubectl port-forward -n $(NAMESPACE) svc/opensearch-cluster-master 9200:9200 & \
	kubectl port-forward -n $(NAMESPACE) svc/obsb-opensearch-dashboards 5601:5601 & \
	wait

zabbix:
	@echo "🌐 Opening Zabbix Web UI..."
	@echo "   URL: http://localhost:8080"
	@echo "   Default credentials: Admin / zabbix"
	kubectl port-forward -n $(NAMESPACE) svc/obsb-zabbix-zabbix-web 8080:80

dashboards:
	@echo "🌐 Opening OpenSearch Dashboards..."
	@echo "   URL: http://localhost:5601"
	@echo "   Credentials: admin / Zx9@gZXWJwYSVvKp7!"
	kubectl port-forward -n $(NAMESPACE) svc/obsb-opensearch-dashboards 5601:5601

opensearch:
	@echo "🔍 Opening OpenSearch API..."
	@echo "   URL: https://localhost:9200 (note: HTTPS with self-signed cert)"
	@echo "   Credentials: admin / Zx9@gZXWJwYSVvKp7!"
	kubectl port-forward -n $(NAMESPACE) svc/opensearch-cluster-master 9200:9200
