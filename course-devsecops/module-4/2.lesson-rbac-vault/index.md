---
kind: lesson

title: RBAC & Secrets Management
description: |
  Least-privilege access with Kubernetes RBAC, why secrets in plain manifests
  are a liability, and how a secrets manager like Vault (dev mode) centralizes
  and controls access to sensitive values. Create a scoped Role and read a
  secret from Vault.

name: rbac-secrets-vault
slug: rbac-secrets-vault

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- kubernetes

tagz:
- rbac
- vault
- secrets
- devsecops

playground:
  name: devsecops-k8s-1ae0b5be

challenges:
  k8s-rbac-a7d48c0f: {}

tasks:
  verify_cluster:
    machine: dev-machine
    user: laborant
    run: |
      if ! kubectl get nodes >/dev/null 2>&1; then
        echo "cluster not reachable"
        exit 1
      fi
      echo "cluster ok"
    hintcheck: |
      echo "Check the cluster:  kubectl get nodes"

  verify_role_created:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cluster
    run: |
      if ! kubectl -n dev get role pod-reader >/dev/null 2>&1; then
        echo "Role pod-reader not found in namespace dev"
        exit 1
      fi
      echo "role present"
    hintcheck: |
      echo "Create a Role named pod-reader in the dev namespace that can only get/list/watch pods."

  verify_least_privilege:
    machine: dev-machine
    user: laborant
    needs:
      - verify_role_created
    run: |
      VERBS=$(kubectl -n dev get role pod-reader -o jsonpath='{.rules[*].verbs[*]}' 2>/dev/null)
      if echo "${VERBS}" | grep -qiE "delete|\*|create|update"; then
        echo "pod-reader has more than read verbs — keep it least-privilege (get/list/watch)"
        exit 1
      fi
      echo "least privilege ok"
    hintcheck: |
      echo "pod-reader must only allow get, list, watch — no create/update/delete/*."

  verify_vault_secret:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cluster
    run: |
      FILE=/home/laborant/vault-read.txt
      if [ ! -f "${FILE}" ]; then
        echo "vault-read.txt not found"
        exit 1
      fi
      if ! grep -qi "db_password\|value\|secret" "${FILE}"; then
        echo "vault-read.txt should contain the secret you read from Vault"
        exit 1
      fi
      echo "vault secret read"
    hintcheck: |
      echo "Store and read a secret from the dev-mode Vault, saving the output to vault-read.txt."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_least_privilege
      - verify_vault_secret
    run: |
      echo "Lesson complete — well done!"
---
