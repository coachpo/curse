# Curse Compose Stack — Makefile
# Usage: make start-<service>, make stop-<service>, make logs-<service>, make status
#
# Services are auto-discovered: any subdirectory containing compose.yml is a service.
# To add a new service, create <name>/compose.yml — no Makefile edits needed.

# Auto-discover services: directories containing compose.yml
SERVICES := $(sort $(patsubst %/compose.yml,%,$(wildcard */compose.yml)))

# Compose command for a given service directory
compose = docker compose -f $(1)/compose.yml

.PHONY: help start-all stop-all status ports services

help: ## Show this help
	@echo "Usage: make <target>"
	@echo ""
	@echo "Discovered services: $(SERVICES)"
	@echo ""
	@echo "Per-service:"
	@echo "  make start-<service>     Pull latest images and start a service"
	@echo "  make stop-<service>      Stop a service"
	@echo "  make restart-<service>   Restart a service"
	@echo "  make logs-<service>      Tail logs for a service"
	@echo ""
	@echo "Bulk:"
	@echo "  make start-all           Start all services"
	@echo "  make stop-all            Stop all services"
	@echo "  make status              Show status of all services"
	@echo ""
	@echo "Info:"
	@echo "  make ports               Show default port assignments"
	@echo "  make services            List discovered services"

# ── Dynamic per-service targets ──────────────────────────────────────

define SERVICE_TARGETS
.PHONY: start-$(1) stop-$(1) restart-$(1) logs-$(1)

start-$(1):
	$$(call compose,$(1)) pull
	$$(call compose,$(1)) up -d

stop-$(1):
	$$(call compose,$(1)) down

restart-$(1): stop-$(1) start-$(1)

logs-$(1):
	$$(call compose,$(1)) logs -f
endef

$(foreach svc,$(SERVICES),$(eval $(call SERVICE_TARGETS,$(svc))))

# ── Bulk targets ─────────────────────────────────────────────────────

start-all: $(addprefix start-,$(SERVICES)) ## Start all services

stop-all: $(addprefix stop-,$(SERVICES)) ## Stop all services

status: ## Show running containers for all services
	@for svc in $(SERVICES); do \
		echo "=== $$svc ==="; \
		docker compose -f $$svc/compose.yml ps 2>/dev/null || echo "  (not running)"; \
		echo ""; \
	done

services: ## List discovered services
	@for svc in $(SERVICES); do echo "  $$svc"; done

ports: ## Show default port assignments
	@echo "Port  | Service              | Env var"
	@echo "------|----------------------|------------------------"
	@echo "3000  | Grafana              | GRAFANA_PORT"
	@echo "4317  | OTLP gRPC            | OTLP_GRPC_PORT"
	@echo "4318  | OTLP HTTP            | OTLP_HTTP_PORT"
	@echo "5000  | Docker Registry      | REGISTRY_PORT"
	@echo "8000  | Portainer edge       | PORTAINER_EDGE_PORT"
	@echo "8080  | Bark                 | BARK_PORT"
	@echo "8081  | Spear (nginx proxy)  | SPEAR_PORT"
	@echo "8082  | Prism gateway (nginx)| PRISM_HTTP_PORT"
	@echo "8083  | Mermaid              | MERMAID_PORT"
	@echo "8084  | Swiperflix proxy     | SWIPERFLIX_PORT"
	@echo "8085  | Whisper proxy        | WHISPER_PORT"
	@echo "8889  | OTEL Prometheus      | OTEL_METRICS_PORT"
	@echo "9000  | Portainer UI         | PORTAINER_PORT"
	@echo "9090  | Prometheus           | PROMETHEUS_PORT"
	@echo "9443  | Portainer HTTPS      | PORTAINER_HTTPS_PORT"
	@echo "13133 | OTEL health check    | OTEL_HEALTH_PORT"
