# Try "docker compose" first, then fallback to "docker-compose"
DOCKER_COMPOSE_COMMAND := $(shell command -v docker-compose >/dev/null 2>&1 && echo docker-compose || (command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 && echo "docker compose"))

# If neither exists, abort
ifeq ($(DOCKER_COMPOSE_COMMAND),)
$(error "Neither docker-compose nor docker compose found in PATH")
endif

all: build

build:
	docker build -t nbe:latest -f docker/Dockerfile --no-cache=true .
build_aarch64:
	docker build -t nbe:aarch64 -f docker/Dockerfile --no-cache=true .
upload_aarch64:
	docker tag nbe:aarch64 ohmegastar/nbe:aarch64
	docker push ohmegastar/nbe:aarch64
upload:
	docker tag nbe:latest ohmegastar/nbe:latest
	docker push ohmegastar/nbe:latest
up:
	COMPOSE_PROJECT_NAME=nbe COMPOSE_IGNORE_ORPHANS=True $(DOCKER_COMPOSE_COMMAND) -f docker-compose.yml up -d
down:
	COMPOSE_PROJECT_NAME=nbe COMPOSE_IGNORE_ORPHANS=True $(DOCKER_COMPOSE_COMMAND) -f docker-compose.yml down
up_aarch64:
	COMPOSE_PROJECT_NAME=nbe COMPOSE_IGNORE_ORPHANS=True $(DOCKER_COMPOSE_COMMAND) -f docker-compose_aarch64.yml up -d
down_aarch64:
	COMPOSE_PROJECT_NAME=nbe COMPOSE_IGNORE_ORPHANS=True $(DOCKER_COMPOSE_COMMAND) -f docker-compose_aarch64.ym down
