.PHONY: help build build-84 build-85 up down test logs clean shell composer

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Default PHP branch
PHP_BRANCH ?= PHP-8.4

help:
	@echo "$(GREEN)Signalforge Build Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Build Commands:$(NC)"
	@echo "  make build      - Build with PHP 8.4 (default)"
	@echo "  make build-84   - Build with PHP 8.4"
	@echo "  make build-85   - Build with PHP 8.5"
	@echo ""
	@echo "$(YELLOW)Docker Commands:$(NC)"
	@echo "  make up         - Start all services"
	@echo "  make down       - Stop all services"
	@echo "  make logs       - Follow logs from app container"
	@echo "  make shell      - Open shell in app container"
	@echo "  make clean      - Remove containers and volumes"
	@echo ""
	@echo "$(YELLOW)Development Commands:$(NC)"
	@echo "  make test       - Run PHPUnit tests in container"
	@echo "  make composer   - Run composer commands (use: make composer CMD='install')"
	@echo ""
	@echo "$(YELLOW)Information:$(NC)"
	@echo "  make php-version  - Show PHP version in container"
	@echo "  make php-modules  - Show loaded PHP modules"
	@echo ""
	@echo "$(RED)Note:$(NC) First build takes 10-15 minutes (compiling PHP from source)"

build:
	@echo "$(YELLOW)Building with PHP_BRANCH=$(PHP_BRANCH)...$(NC)"
	PHP_BRANCH=$(PHP_BRANCH) docker compose build --no-cache
	@echo "$(GREEN)Build complete!$(NC)"

build-84:
	@$(MAKE) build PHP_BRANCH=PHP-8.4

build-85:
	@$(MAKE) build PHP_BRANCH=PHP-8.5

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
