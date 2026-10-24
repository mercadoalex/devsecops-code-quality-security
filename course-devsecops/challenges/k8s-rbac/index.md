---
kind: challenge

title: 'Least-Privilege RBAC + Vault Secret'

description: |
  Design a least-privilege Role for a monitoring service account that can read
  pods and nothing else, bind it, and store the service's credential in Vault
  rather than a manifest. Addresses OWASP Kubernetes K03 and K08.

categories:
  - security
  - kubernetes

tagz:
  - rbac
  - vault
  - secrets
  - devsecops

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-k8s-1ae0b5be

tasks:
  verify_sa:
    machine: dev-machine
    user: laborant
    run: |
      if ! kubectl -n dev get serviceaccount monitor >/dev/null 2>&1; then
        echo "ServiceAccount monitor not found in namespace dev"
        exit 1
      fi
      echo "sa ok"

  verify_role_readonly:
    machine: dev-machine
    user: laborant
    needs:
      - verify_sa
    run: |
      if ! kubectl -n dev get role monitor-pods >/dev/null 2>&1; then
        echo "Role monitor-pods not found"
        exit 1
      fi
      VERBS=$(kubectl -n dev get role monitor-pods -o jsonpath='{.rules[*].verbs[*]}' 2>/dev/null)
      if echo "${VERBS}" | grep -qiE "delete|create|update|patch|\*"; then
        echo "monitor-pods grants write verbs — keep it read-only"
        exit 1
      fi
      echo "role read-only"

  verify_binding:
    machine: dev-machine
    user: laborant
    needs:
      - verify_role_readonly
    run: |
      if ! kubectl -n dev get rolebinding monitor-binding >/dev/null 2>&1; then
        echo "RoleBinding monitor-binding not found"
        exit 1
      fi
      CANI=$(kubectl auth can-i delete pods -n dev --as=system:serviceaccount:dev:monitor 2>/dev/null || echo no)
      if echo "${CANI}" | grep -qi "yes"; then
        echo "monitor can delete pods — it should not be able to"
        exit 1
      fi
      echo "binding least-privilege"

  verify_vault_credential:
    machine: dev-machine
    user: laborant
    needs:
      - verify_sa
    run: |
      export VAULT_ADDR='http://127.0.0.1:8200'
      export VAULT_TOKEN='root'
      if ! vault kv get secret/monitor >/dev/null 2>&1; then
        echo "No secret stored at secret/monitor in Vault"
        exit 1
      fi
      echo "vault credential stored"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_binding
      - verify_vault_credential
    run: |
      echo "Challenge complete!"
---

## Lock down a monitoring service

A monitoring service needs to *read* pods and nothing else, and its credential
must not live in a manifest. Build it:

1. Create a `monitor` ServiceAccount in the `dev` namespace.
2. Create a `monitor-pods` Role that allows only `get`, `list`, `watch` on pods
   (no write verbs).
3. Bind it with a `monitor-binding` RoleBinding. Confirm with `kubectl auth can-i`
   that `monitor` **cannot** delete pods.
4. Store the service's credential in Vault at `secret/monitor` (dev mode:
   `VAULT_ADDR=http://127.0.0.1:8200`, token `root`).

::hint-box
---
:summary: The commands
---
```bash
kubectl -n dev create serviceaccount monitor
kubectl -n dev create role monitor-pods --verb=get,list,watch --resource=pods
kubectl -n dev create rolebinding monitor-binding --role=monitor-pods --serviceaccount=dev:monitor
kubectl auth can-i delete pods -n dev --as=system:serviceaccount:dev:monitor   # -> no

export VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root
vault kv put secret/monitor token='generated-sa-token-value'
```
::

::simple-task
---
:tasks: tasks
:name: verify_sa
---
#active
Create the `monitor` ServiceAccount in `dev`.

#completed
ServiceAccount created. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_role_readonly
---
#active
Create a read-only `monitor-pods` Role (get/list/watch on pods only).

#completed
Role is read-only. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_binding
---
#active
Bind the role and confirm `monitor` cannot delete pods.

#completed
Binding is least-privilege. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_vault_credential
---
#active
Store the service credential in Vault at `secret/monitor`.

#completed
Credential stored in Vault. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — the service is least-privilege with no secret in a manifest.

#completed
RBAC + Vault challenge complete. ✓
::
