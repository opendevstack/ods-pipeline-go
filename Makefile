SHELL = /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

##@ General

# help target is based on https://github.com/operator-framework/operator-sdk/blob/master/release/Makefile.
.DEFAULT_GOAL := help
help: ## Show this help screen.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
.PHONY: help

.PHONY: lint-shell

##@ Building

images: image-go-toolset ## Build images.
.PHONY: images

image-go-toolset: ## Build go-toolset image.
	docker build \
        -f build/images/Dockerfile.go-toolset \
		-t localhost:5000/ods-pipeline/go-toolset \
		.
.PHONY: image-go-toolset

tasks: ## Render tasks. Use VERSION=1.0.0 make tasks to render specific version.
	go run github.com/opendevstack/ods-pipeline/cmd/render-manifest \
		-data ImageRepository=ghcr.io/opendevstack/ods-pipeline-go \
		-data Version=$$(cat version) \
		-template build/tasks/build.yaml \
		-destination tasks/build.yaml
.PHONY: tasks

step-actions: ## Render step-actions. Use VERSION=1.0.0 make step-actions to render specific version.
	go run github.com/opendevstack/ods-pipeline/cmd/render-manifest \
		-data ImageRepository=ghcr.io/opendevstack/ods-pipeline-go \
		-data Version=$$(cat version) \
		-template build/step-actions/build.yaml \
		-destination step-actions/build.yaml
.PHONY: step-actions

docs: tasks step-actions ## Render documentation for tasks and step-actions.
	go run github.com/opendevstack/ods-pipeline/cmd/render-doc \
		-manifest=step-actions/build.yaml \
		-destination=docs/step-action-build.adoc
	go run github.com/opendevstack/ods-pipeline/cmd/render-doc \
		-manifest=tasks/build.yaml \
		-description=build/docs/build.adoc \
		-destination=docs/task-build.adoc
.PHONY: docs

##@ Testing

test: test-e2e ## Run complete testsuite.
.PHONY: test

test-e2e: ## Run testsuite of end-to-end task runs.
	go test -v -count=1 -timeout 10m ./test/e2e/...
.PHONY: test-e2e

##@ CI

check-docs: docs ## Check docs are up-to-date
	@printf "Docs / tasks are " && git diff --quiet docs tasks && echo "up-to-date." || (echo "not up-to-date! Run 'make docs' to update."; false)
.PHONY: check-docs

ci: check-docs test ## Run CI tasks
.PHONY: ci
