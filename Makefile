.PHONY: help install sync test lint format clean deploy cluster-create cluster-delete

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install dependencies using uv
	uv sync
	uv sync --group dev

sync: ## Sync dependencies
	uv sync

test: ## Run tests with coverage
	uv run pytest tests/ -v --cov=scripts --cov-report=term-missing

lint: ## Lint and check code
	uv run ruff check scripts/
	uv run mypy scripts/
	uv run ansible-lint ansible/

format: ## Format code
	uv run ruff format scripts/
	uv run ruff check --fix scripts/

clean: ## Clean generated files
	rm -rf .pytest_cache
	rm -rf .ruff_cache
	rm -rf .mypy_cache
	rm -rf htmlcov
	rm -rf dist
	rm -rf build
	rm -rf *.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete

deploy: ## Deploy to Kubernetes
	uv run python scripts/deploy.py

cluster-create: ## Create Kind cluster
	./scripts/create-cluster.sh

cluster-delete: ## Delete Kind cluster
	kind delete cluster --name todo-app-cluster

pre-commit: ## Install pre-commit hooks
	uv run pre-commit install

pre-commit-run: ## Run pre-commit on all files
	uv run pre-commit run --all-files
