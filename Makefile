# Curse Compose Stack — Makefile
# Usage: make start-<service>, make stop-<service>, make logs-<service>, make status
#
# Services are auto-discovered: any subdirectory containing compose.yml is a service.
# To add a new service, create <name>/compose.yml — no Makefile edits needed.

# Auto-discover services: directories containing compose.yml
SERVICES := $(sort $(patsubst %/compose.yml,%,$(wildcard */compose.yml)))

# Compose command for a given service directory
compose = docker compose -f $(1)/compose.yml

# Optional selector args for `make start-<service> ...`
# Supported forms:
#   make start-<service>
#   make start-<service> <tag>
#   make start-<service> last [n]
START_SERVICE_TARGET := $(filter $(addprefix start-,$(SERVICES)),$(firstword $(MAKECMDGOALS)))
START_SERVICE_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
START_IMAGE_SELECTOR := $(word 1,$(START_SERVICE_ARGS))
START_IMAGE_ROLLBACK_DEPTH := $(word 2,$(START_SERVICE_ARGS))
START_IMAGE_EXTRA_ARGS := $(wordlist 3,$(words $(START_SERVICE_ARGS)),$(START_SERVICE_ARGS))

ifneq ($(START_SERVICE_TARGET),)
ifneq ($(strip $(START_SERVICE_ARGS)),)
.PHONY: $(START_SERVICE_ARGS)
$(START_SERVICE_ARGS):
	@:
endif
endif

.PHONY: help start-all stop-all status ports services prune-images clone-prism-b-from-prism-a

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

define START_SERVICE
	@selector="$(START_IMAGE_SELECTOR)"; \
	depth="$(START_IMAGE_ROLLBACK_DEPTH)"; \
	extra_args="$(START_IMAGE_EXTRA_ARGS)"; \
	compose_cmd="$(call compose,$(1))"; \
	tmp_services=""; \
	tmp_images=""; \
	tmp_pairs=""; \
	override_file=""; \
	cleanup() { rm -f "$$tmp_services" "$$tmp_images" "$$tmp_pairs" "$$override_file"; }; \
	trap cleanup EXIT INT TERM HUP; \
	resolve_tag() { \
		image_repo="$$1"; \
		selector_value="$$2"; \
		rollback_depth="$$3"; \
		case "$$selector_value" in \
			last) \
				if [ -z "$$rollback_depth" ]; then rollback_depth=1; fi; \
				case "$$rollback_depth" in \
					''|*[!0-9]*|0) echo "[$(1)] invalid rollback depth '$$rollback_depth'; use a positive integer." >&2; return 1 ;; \
				esac; \
				selected_tag="$$(docker image ls "$$image_repo" --format '{{.Tag}}' | awk -v wanted="$$rollback_depth" '\
					$$0 != "<none>" && $$0 != "latest" && !seen[$$0]++ { \
						count++; \
						if (count == wanted) { \
							print; \
							exit; \
						} \
					} \
				')"; \
				if [ -z "$$selected_tag" ]; then \
					echo "[$(1)] no rollback tag found for $$image_repo at depth $$rollback_depth." >&2; \
					return 1; \
				fi; \
				printf '%s\n' "$$selected_tag"; \
				;; \
			'') \
				printf '%s\n' latest; \
				;; \
			*) \
				if [ -n "$$rollback_depth" ]; then \
					echo "[$(1)] unexpected extra argument '$$rollback_depth'; use 'make start-$(1) last [n]' or 'make start-$(1) <tag>'." >&2; \
					return 1; \
				fi; \
				printf '%s\n' "$$selector_value"; \
				;; \
		esac; \
	}; \
	if [ -n "$$extra_args" ]; then \
		echo "[$(1)] too many arguments '$$extra_args'; use 'make start-$(1)', 'make start-$(1) <tag>', or 'make start-$(1) last [n]'." >&2; \
		exit 1; \
	fi; \
	if [ -n "$$selector" ]; then \
		tmp_services="$$(mktemp "/tmp/curse-$(1)-services.XXXXXX")"; \
		tmp_images="$$(mktemp "/tmp/curse-$(1)-images.XXXXXX")"; \
		tmp_pairs="$$(mktemp "/tmp/curse-$(1)-image-pairs.XXXXXX")"; \
		override_file="$$(mktemp "/tmp/curse-$(1)-image-override.XXXXXX")"; \
		$(call compose,$(1)) config --services > "$$tmp_services"; \
		$(call compose,$(1)) config --images > "$$tmp_images"; \
		awk 'NR==FNR { services[NR] = $$0; next } { print services[FNR] "|" $$0 }' "$$tmp_services" "$$tmp_images" > "$$tmp_pairs"; \
		printf "services:\n" > "$$override_file"; \
		rewritten=0; \
		while IFS='|' read -r service image; do \
			case "$$image" in \
				*@*) continue ;; \
				*:* ) repo="$${image%:*}"; current_tag="$${image##*:}" ;; \
				* ) repo="$$image"; current_tag="" ;; \
			esac; \
			if [ "$$current_tag" != "latest" ]; then \
				continue; \
			fi; \
			target_tag="$$(resolve_tag "$$repo" "$$selector" "$$depth")" || exit $$?; \
			printf "  %s:\n    image: %s:%s\n" "$$service" "$$repo" "$$target_tag" >> "$$override_file"; \
			rewritten=$$((rewritten + 1)); \
		done < "$$tmp_pairs"; \
		if [ "$$rewritten" -eq 0 ]; then \
			echo "[$(1)] no latest-tagged images found to override." >&2; \
			exit 1; \
		fi; \
		compose_cmd="docker compose -f $(1)/compose.yml -f $$override_file"; \
		if [ "$$selector" = "last" ]; then \
			echo "[$(1)] using locally cached rollback tag(s) from depth $${depth:-1}."; \
			$$compose_cmd up -d --pull never; \
		else \
			echo "[$(1)] pulling tag '$$selector' for latest-tagged images."; \
			$$compose_cmd pull; \
			$$compose_cmd up -d; \
		fi; \
	else \
		$$compose_cmd pull; \
		$$compose_cmd up -d; \
	fi
endef

help: ## Show this help
	@echo "Usage: make <target>"
	@echo ""
	@echo "Discovered services: $(SERVICES)"
	@echo ""
	@echo "Per-service:"
	@echo "  make start-<service> [tag]     Start a service (default tag: latest)"
	@echo "  make start-<service> last [n]  Roll back latest-tagged images using local tags"
	@echo "    Examples:"
	@echo "      make start-bark"
	@echo "      make start-bark 1.2.3"
	@echo "      make start-bark last"
	@echo "      make start-bark last 2"
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
	@echo ""
	@echo "Utilities:"
	@echo "  make clone-prism-b-from-prism-a  Clone Prism A postgres volume into Prism B"

# ── Dynamic per-service targets ──────────────────────────────────────

define SERVICE_TARGETS
.PHONY: start-$(1) stop-$(1) restart-$(1) logs-$(1)

start-$(1):
	$$(call START_SERVICE,$(1))
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

clone-prism-b-from-prism-a: ## Clone Prism A postgres volume into Prism B
	./prism-b/clone-prism-a-volume.sh

ports: ## Show default port assignments
	@echo "Port  | Service             | Env var              | App                                           | GitHub"
	@echo "------|---------------------|----------------------|-----------------------------------------------|----------------------------------------"
	@echo "5000  | Docker Registry     | REGISTRY_PORT        | Private container image registry              | -"
	@echo "8000  | Portainer edge      | PORTAINER_EDGE_PORT  | Portainer edge tunnel endpoint                | -"
	@echo "8080  | Bark                | BARK_PORT            | iOS push notification gateway                 | -"
	@echo "8081  | Herald (nginx)      | HERALD_PORT          | Message ingest and rule-based notifications   | https://github.com/coachpo/herald"
	@echo "8083  | Mermaid             | MERMAID_PORT         | Live Mermaid diagram editor                   | -"
	@echo "8084  | Swiperflix (nginx)  | SWIPERFLIX_PORT      | TikTok-style video player stack               | https://github.com/coachpo/swiperflix"
	@echo "8085  | Whisper (caddy)     | WHISPER_PORT         | Dictation training platform                   | https://github.com/coachpo/last-whisper"
	@echo "8086  | AssppWeb            | ASSPP_PORT           | iOS IPA install/acquisition web UI            | -"
	@echo "8087  | Prism A (nginx)     | PRISM_A_PORT         | Self-hosted LLM proxy gateway                 | https://github.com/coachpo/prism"
	@echo "8088  | Prism B (nginx)     | PRISM_B_PORT         | Prism clone for A/B testing                   | https://github.com/coachpo/prism"
	@echo "8432  | Prism B Postgres    | PRISM_B_POSTGRES_PORT | Direct host access to Prism B PostgreSQL      | https://github.com/coachpo/prism"
	@echo "8089  | Clay                | CLAY_PORT            | OpenAI-compatible API proxy                   | https://github.com/coachpo/clay"
	@echo "8091  | n8n                 | N8N_PORT             | Workflow automation platform                  | https://github.com/n8n-io/n8n"
	@echo "8317  | CLIProxyAPI         | CLI_PROXY_API_PORT   | Multi-provider CLI/API proxy                  | https://github.com/router-for-me/CLIProxyAPI"
	@echo "9000  | Portainer UI        | PORTAINER_PORT       | Docker management dashboard                   | -"
	@echo "9443  | Portainer HTTPS     | PORTAINER_HTTPS_PORT | Docker management dashboard (HTTPS)           | -"
