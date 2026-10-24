# DevSecOps course — rootfs image builds
# Usage:
#   make all REGISTRY=ghcr.io/<your-namespace>
#   make push REGISTRY=ghcr.io/<your-namespace>
#
# Build order: vmbase -> base -> ai.
# Run from the rootfs/ directory (build context = .).
#
# NOTE: there is NO custom k8s image. The Kubernetes playground is created with
#   `labctl playground create devsecops-k8s --base k3s` + an init-task manifest
#   (playground/devsecops-k8s/manifest.yaml) — it layers our tools onto the
#   platform's healthy k3s cluster rather than baking a fragile custom rootfs.

REGISTRY ?= ghcr.io/mercadoalex
PLATFORM := linux/amd64
TAG      ?= latest

.PHONY: all vmbase base ai push clean

all: base ai

vmbase:
	docker build --platform $(PLATFORM) \
	  -f common/Dockerfile.vmbase \
	  -t devsecops-vmbase:$(TAG) .

base: vmbase
	docker build --platform $(PLATFORM) \
	  -f base/Dockerfile \
	  -t $(REGISTRY)/devsecops-base:$(TAG) .

# ai builds FROM the slim vmbase (NOT base) — it needs only Ollama + Garak +
# Python, so inheriting the 3.5 GB base was pure bloat.
ai: vmbase
	docker build --platform $(PLATFORM) \
	  -f ai/Dockerfile \
	  --build-arg BASE=devsecops-vmbase:$(TAG) \
	  -t $(REGISTRY)/devsecops-ai:$(TAG) .

push:
	docker push $(REGISTRY)/devsecops-base:$(TAG)
	docker push $(REGISTRY)/devsecops-ai:$(TAG)

clean:
	-docker rmi devsecops-vmbase:$(TAG) \
	  $(REGISTRY)/devsecops-base:$(TAG) \
	  $(REGISTRY)/devsecops-ai:$(TAG)
