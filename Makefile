.PHONY: help build up down test logs clean shell composer

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help:
	@echo "$(GREEN)Signalforge Development Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Docker Commands:$(NC)"
	@echo "  make build    - Build Docker images (compiles PHP 8.4 from source)"
	@echo "  make up       - Start all services"
	@echo "  make down     - Stop all services"
	@echo "  make logs     - Follow logs from app container"
	@echo "  make shell    - Open shell in app container"
	@echo "  make clean    - Remove containers and volumes"
	@echo ""
	@echo "$(YELLOW)Development Commands:$(NC)"
	@echo "  make test     - Run PHPUnit tests in container"
	@echo "  make composer - Run composer commands (use: make composer CMD='install')"
	@echo ""
	@echo "$(YELLOW)Information:$(NC)"
	@echo "  make php-version  - Show PHP version in container"
	@echo "  make php-modules  - Show loaded PHP modules"
	@echo ""
	@echo "$(RED)Note:$(NC) First 'make build' takes 10-15 minutes (compiling PHP from source)"

build:
	@echo "$(YELLOW)Building Docker images (this may take 10-15 minutes the first time)...$(NC)"
	docker compose build --no-cache
	@echo "$(GREEN)Build complete!$(NC)"

up:
	@echo "$(YELLOW)Starting all services...$(NC)"
	docker compose up -d
	@echo ""
	@echo "$(GREEN)Services started successfully!$(NC)"
	@echo ""
	@echo "Framework available at: $(GREEN)http://localhost:8888$(NC)"
	@echo "MySQL available at:     localhost:33060"
	@echo "Redis available at:     localhost:63790"

down:
	@echo "$(YELLOW)Stopping all services...$(NC)"
	docker compose down
	@echo "$(GREEN)Services stopped.$(NC)"

test:
	@echo "$(YELLOW)Running PHPUnit tests...$(NC)"
	docker compose exec app sh -c "cd /var/www && ./vendor/bin/phpunit"

logs:
	docker compose logs -f app

shell:
	docker compose exec app sh

clean:
	@echo "$(RED)Removing containers and volumes...$(NC)"
	docker compose down -v
	@echo "$(GREEN)Cleanup complete.$(NC)"

composer:
	docker compose exec app sh -c "cd /var/www && composer $(CMD)"

php-version:
	@docker compose exec app php -v

php-modules:
	@docker compose exec app php -m

# Install composer dependencies
install:
	@echo "$(YELLOW)Installing composer dependencies...$(NC)"
	docker compose exec app sh -c "cd /var/www && composer install"
	@echo "$(GREEN)Dependencies installed.$(NC)"

# Run composer install if vendor doesn't exist, then run tests
check: up
	@if [ ! -d "../framework/vendor" ]; then \
		echo "$(YELLOW)Installing dependencies...$(NC)"; \
		docker compose exec app sh -c "cd /var/www && composer install"; \
	fi
	@echo "$(YELLOW)Running tests...$(NC)"
	docker compose exec app sh -c "cd /var/www && ./vendor/bin/phpunit"

# Verify extensions are loaded
verify-extensions:
	@echo "$(YELLOW)Verifying Signalforge extensions...$(NC)"
	@docker compose exec app php -m | grep -E "router|request|keyshare" || echo "$(RED)Extensions not loaded!$(NC)"

# Curl test
curl-test:
	@echo "$(YELLOW)Testing framework endpoint...$(NC)"
	@curl -s http://localhost:8888 | python3 -m json.tool 2>/dev/null || curl http://localhost:8888
