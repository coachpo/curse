# Curse Compose Stack — Makefile
# Usage: make start-<service>, make stop-<service>, make logs-<service>, make status
#
# Services are auto-discovered: any subdirectory containing compose.yml is a service.
# To add a new service, create <name>/compose.yml — no Makefile edits needed.

# Auto-discover services: directories containing compose.yml
SERVICES := $(sort $(patsubst %/compose.yml,%,$(wildcard */compose.yml)))

# Compose command for a given service directory
compose = docker compose -f $(1)/compose.yml

.PHONY: help start-all stop-all status ports services prune-images

# Print published host ports for a service after start/restart.
# Uses runtime data from `docker compose ps --format json` to reflect real bindings.
define PRINT_RUNNING_PORTS
	@if command -v jq >/dev/null 2>&1; then \
		ports="$$(docker compose -f $(1)/compose.yml ps --format json 2>/dev/null | jq -r '.[] | select((.Publishers | type) == "array" and (.Publishers | length) > 0) | "  - \(.Service): " + (.Publishers | map((if .URL and .URL != "" then .URL + ":" else "" end) + ((.PublishedPort // "unknown")|tostring) + "->" + ((.TargetPort // "unknown")|tostring) + "/" + ((.Protocol // "tcp")|tostring)) | join(", "))' 2>/dev/null || true)"; \
	else \
		ports="$$(docker compose -f $(1)/compose.yml ps --format '{{.Service}}|{{.Publishers}}' 2>/dev/null | awk -F'|' '\
			$$2 != "" && $$2 != "[]" { \
				service = $$1; \
				pubs = $$2; \
				if (pubs ~ /\{[^}]+\}/) { \
					gsub(/^\[/, "", pubs); \
					gsub(/\]$$/, "", pubs); \
					gsub(/\} \{/, "}\n{", pubs); \
					n = split(pubs, items, /\n/); \
					out = ""; \
					for (i = 1; i <= n; i++) { \
						item = items[i]; \
						gsub(/[{}]/, "", item); \
						gsub(/^[[:space:]]+|[[:space:]]+$$/, "", item); \
						if (item == "") continue; \
						m = split(item, f, /[[:space:]]+/); \
						host = (m >= 1 && f[1] != "" ? f[1] : "0.0.0.0"); \
						target = (m >= 2 && f[2] != "" ? f[2] : "unknown"); \
						published = (m >= 3 && f[3] != "" ? f[3] : "unknown"); \
						proto = (m >= 4 && f[4] != "" ? f[4] : "tcp"); \
						if (host == "*") host = "0.0.0.0"; \
						if (host ~ /:/ && host !~ /^\[.*\]$$/) host = "[" host "]"; \
						entry = host ":" published "->" target "/" proto; \
						out = (out == "" ? entry : out ", " entry); \
					} \
					if (out != "") print "  - " service ": " out; \
				} else { \
					gsub(/^\[/, "", pubs); \
					gsub(/\]$$/, "", pubs); \
					print "  - " service ": " pubs; \
				} \
			} \
		')"; \
	fi; \
	if [ -n "$$ports" ]; then \
		echo "[$(1)] running on:"; \
		echo "$$ports"; \
	else \
		echo "[$(1)] started (no published host ports detected)."; \
	fi
endef

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
	@echo "  make prune-images        Delete unused/untagged service images"
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
	$$(call PRINT_RUNNING_PORTS,$(1))

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

prune-images: ## Delete unused/untagged images for discovered services
	@echo "Removing unused untagged images for discovered services..."
	@repos="$$(for svc in $(SERVICES); do docker compose -f $$svc/compose.yml config --images 2>/dev/null || true; done \
		| awk 'NF { ref=$$0; sub(/@.*/, "", ref); if (match(ref, /:[^\/:]*$$/)) ref=substr(ref, 1, RSTART-1); print ref }' \
		| sort -u)"; \
	if [ -z "$$repos" ]; then \
		echo "No service image repositories discovered."; \
		exit 0; \
	fi; \
	removed=0; \
	for repo in $$repos; do \
		ids="$$(docker image ls --format '{{.Repository}}|{{.Tag}}|{{.ID}}' \
			| awk -F'|' -v repo="$$repo" '$$1 == repo && $$2 == "<none>" { print $$3 }' \
			| sort -u)"; \
		for id in $$ids; do \
			if [ -z "$$(docker ps -aq --filter ancestor=$$id)" ]; then \
				echo "  removing $$repo ($$id)"; \
				docker image rm "$$id" >/dev/null || true; \
				removed=$$((removed + 1)); \
			fi; \
		done; \
	done; \
	echo "Removed $$removed unused untagged discovered service image(s)."

ports: ## Show default port assignments
	@echo "Port  | Service             | Env var              | App                                           | GitHub"
	@echo "------|---------------------|----------------------|-----------------------------------------------|----------------------------------------"
	@echo "5000  | Docker Registry     | REGISTRY_PORT        | Private container image registry              | -"
	@echo "8000  | Portainer edge      | PORTAINER_EDGE_PORT  | Portainer edge tunnel endpoint                | -"
	@echo "8080  | Bark                | BARK_PORT            | iOS push notification gateway                 | -"
	@echo "8081  | Herald (nginx)      | HERALD_PORT          | Message ingest and rule-based notifications   | https://github.com/coachpo/herald"
	@echo "8082  | Prism (nginx)       | PRISM_PORT           | Self-hosted LLM proxy gateway                 | https://github.com/coachpo/prism"
	@echo "8083  | Mermaid             | MERMAID_PORT         | Live Mermaid diagram editor                   | -"
	@echo "8084  | Swiperflix (nginx)  | SWIPERFLIX_PORT      | TikTok-style video player stack               | https://github.com/coachpo/swiperflix"
	@echo "8085  | Whisper (caddy)     | WHISPER_PORT         | Dictation training platform                   | https://github.com/coachpo/last-whisper"
	@echo "8086  | AssppWeb            | ASSPP_PORT           | iOS IPA install/acquisition web UI            | -"
	@echo "8087  | Clay                | CLAY_PORT            | OpenAI-compatible API proxy                   | https://github.com/coachpo/clay"
	@echo "8088  | Prism B (nginx)     | PRISM_B_PORT         | Prism clone for A/B testing                   | https://github.com/coachpo/prism"
	@echo "9000  | Portainer UI        | PORTAINER_PORT       | Docker management dashboard                   | -"
	@echo "9443  | Portainer HTTPS     | PORTAINER_HTTPS_PORT | Docker management dashboard (HTTPS)           | -"
