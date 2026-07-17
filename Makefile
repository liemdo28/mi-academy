.PHONY: setup dev test lint migrate seed reset-local stop

COMPOSE = docker compose -f infrastructure/docker/docker-compose.yml

# Install Python + Flutter dependencies for local development.
# Requires melos (`dart pub global activate melos`) to already be on PATH.
setup:
	pip install -r apps/api/requirements.txt
	melos bootstrap

# Start the local stack (Postgres, Redis, API with reload).
dev:
	$(COMPOSE) up

# Run backend + game-core tests. Does not require the docker stack to be running
# (uses SQLite by default per .env.example).
test:
	python -m pytest packages/game_core/tests tests -q

# Static analysis: Flutter analyze + Dart format check across all packages.
lint:
	melos run analyze
	melos run format

# Apply pending Alembic migrations against DATABASE_URL (defaults to local sqlite).
migrate:
	cd apps/api && python -m alembic upgrade head

# Seed the local database with sample lessons/questions/games.
seed:
	python -m infrastructure.seed.seed_data

# Destroy and recreate the local docker stack, including its data volumes.
# Local environment ONLY — refuses to run against anything else.
reset-local:
	@if [ "$$APP_ENV" != "" ] && [ "$$APP_ENV" != "local" ] && [ "$$APP_ENV" != "development" ]; then \
		echo "refusing to run reset-local: APP_ENV=$$APP_ENV is not local/development"; \
		exit 1; \
	fi
	@echo "WARNING: this destroys all local database data. Ctrl+C within 5s to abort."
	@sleep 5
	$(COMPOSE) down -v

# Stop the local stack without destroying data volumes.
stop:
	$(COMPOSE) down
