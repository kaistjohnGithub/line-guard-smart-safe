# Line Guard Smart Safe — Docker commands
# Works on WSL, Linux, and macOS
# Usage: make up | make down | make logs | make build | make clean

COMPOSE = docker compose

.PHONY: up down build logs ps clean db-shell restart

## Start all services (build if needed)
up:
	$(COMPOSE) up -d --build

## Start without rebuilding
start:
	$(COMPOSE) up -d

## Stop all services
down:
	$(COMPOSE) down

## Stop and remove volumes (WARNING: deletes DB data)
clean:
	$(COMPOSE) down -v --remove-orphans

## Rebuild images without cache
build:
	$(COMPOSE) build --no-cache

## Show logs (follow)
logs:
	$(COMPOSE) logs -f

## Show running containers
ps:
	$(COMPOSE) ps

## Restart all services
restart:
	$(COMPOSE) restart

## Connect to PostgreSQL shell
db-shell:
	$(COMPOSE) exec db psql -U ssg -d ssg_db

## Start with pgAdmin GUI (port 5050)
up-tools:
	$(COMPOSE) --profile tools up -d --build

## Show backend logs only
logs-backend:
	$(COMPOSE) logs -f backend

## Show frontend logs only
logs-frontend:
	$(COMPOSE) logs -f frontend
