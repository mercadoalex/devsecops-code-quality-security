---
kind: course

title: "DevSecOps: Code Quality & Security"

description: |-
  Hands-on DevSecOps training — from Shift-Left culture and the OWASP Top 10 to
  static analysis, container and Kubernetes hardening, secure CI/CD, GitOps, and
  LLM security. Everything runs in a pre-configured browser lab with Docker,
  Trivy, SonarQube, Kyverno, Vault, Argo CD, Gitleaks, Falco, Ollama and Garak
  ready on first boot. No local setup required.

categories:
- security
- ci-cd

tagz:
- devsecops
- trivy
- kyverno
- semgrep
- cosign

createdAt: 2026-10-23
updatedAt: 2026-10-23

cover: __static__/cover.png
---

## What you'll learn

- Apply the Shift-Left principle and build a DevSecOps culture across the SDLC
- Map real vulnerabilities to the OWASP Top 10 and the OWASP Kubernetes Top 10
- Run static application security testing (SAST) with SonarQube and manage technical debt
- Harden Docker images, scan for CVEs, and generate SBOMs with Trivy
- Secure Kubernetes with policy-as-code (Kyverno), secrets management (Vault), network policies and RBAC
- Build secure CI/CD pipelines with secret scanning (Gitleaks), image signing and GitOps (Argo CD)
- Detect threats at runtime with Falco
- Scan local LLMs for vulnerabilities and mitigate prompt injection (OWASP LLM Top 10) with Garak and Ollama
- Wire an end-to-end DevSecOps pipeline from commit to deploy with active security gates

## Course structure

| Unit | Topic | Core tools | Duration |
|---|---|---|---|
| 1 | DevSecOps Foundations & Secure SDLC | Trivy, Docker | 3 h |
| 2 | Code Quality / SAST | SonarQube | 4 h |
| 3 | Container Security | Trivy (CVE + SBOM) | 3 h |
| 4 | Kubernetes Security | Kyverno, Vault, RBAC | 3 h |
| 5 | Secure CI/CD & GitOps | Argo CD, Gitleaks, Falco, image signing | 3 h |
| 6 | AI applied to DevSecOps | Garak, Ollama | 2 h |
| 7 | End-to-end integrator capstone | Units 2–5 tools combined | 2 h |

## Lab environment

Every lesson runs in a live browser-based environment — no installation needed.

| Service | Purpose |
|---|---|
| Docker | Build and scan container images |
| Trivy | CVE scanning + SBOM generation |
| SonarQube | Static analysis (SAST) |
| Kubernetes (kind/k3s) | Policy-as-code, RBAC, network policies |
| Kyverno | Admission policy engine |
| Vault | Secrets management |
| Argo CD | GitOps continuous delivery |
| Gitleaks | Secret scanning |
| Falco | Runtime threat detection |
| Ollama + Garak | Local LLM serving + LLM vulnerability scanning |

## Prerequisites

- Comfort with the Linux command line (cd, ls, cat, editing files)
- Basic Git (clone, commit, push)
- Basic Docker familiarity (images vs containers) — a refresher is included
- No prior security experience required

## Language / Idioma

The course is written in **English**. Each lesson ends with a collapsible
**"Versión en español"** hint box that summarises the lesson in Spanish, so the
material is fully followable by Spanish-speaking learners.
