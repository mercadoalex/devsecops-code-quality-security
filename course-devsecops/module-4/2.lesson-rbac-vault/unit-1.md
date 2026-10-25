---
kind: unit

title: RBAC & Secrets Management

name: rbac-secrets-vault-unit-1
---

## A service account that can do anything is a breach waiting to happen

When an attacker compromises a workload in your cluster, the damage they can do is bounded by one thing: **what that workload was allowed to do.** If its service account could read every secret and delete any pod, a single compromised container becomes a cluster-wide incident. If it could only list pods in one namespace, the blast radius is tiny.

That boundary is **RBAC** — Role-Based Access Control. And the sensitive values a workload reaches for — database passwords, API keys — should not sit in plain Kubernetes manifests at all. They belong in a **secrets manager** like **Vault**, which stores them centrally, controls who can read them, and leaves an audit trail.

::image-box
---
:src: __static__/rbac-vault-v1.png
:alt: Two-panel diagram. Left panel "RBAC" shows a ServiceAccount bound via a RoleBinding to a Role that lists only get/list/watch on pods in the dev namespace, with a red X over attempts to read secrets or act in other namespaces. Right panel "Secrets" shows an app requesting a database password from a central Vault server, which checks a policy and returns the secret, instead of the password being hard-coded in a YAML manifest
---
_RBAC bounds what a workload can do; Vault bounds what it can read. Together they shrink the blast radius of any single compromise._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tools:** Kubernetes RBAC (built in, Apache 2.0) + HashiCorp Vault in **dev mode** (MPL-2.0 / BUSL depending on version — we use an older MPL build or the OpenBao MPL-2.0 fork)
- **Why dev mode:** a production Vault runs sealed, HA, with storage backends — far too heavy for a microVM. **`vault server -dev`** runs in-memory, auto-unsealed, single process, perfect for learning the workflow in ~100 MB RAM. **Never use dev mode in production** — it keeps everything in memory and is unsealed with a known root token.
- **Alternative:** OpenBao (MPL-2.0) is the open-source fork of Vault if license matters; the commands are the same.
- **Playground:** `devsecops-k8s`.
::

::hint-box
---
:summary: Why not just use Kubernetes Secrets? They exist for this.
---
Kubernetes Secrets are only **base64-encoded, not encrypted**, by default — anyone who can read the Secret object (or etcd) reads the value. They're fine for low-sensitivity config, but for real credentials a dedicated manager adds: encryption at rest, fine-grained access policies, dynamic short-lived secrets, rotation, and an audit log of every access. Vault (or OpenBao, or a cloud secrets manager) is the grown-up answer. This maps to OWASP Kubernetes **K08: Secrets Management Failures**.
::

---

## 1. Least privilege with RBAC

RBAC has four objects. Two define *what* is allowed, two bind it to *whom*:

| Object | Scope | Answers |
|---|---|---|
| **Role** | one namespace | what actions on what resources |
| **ClusterRole** | whole cluster | same, cluster-wide |
| **RoleBinding** | one namespace | who gets a Role |
| **ClusterRoleBinding** | whole cluster | who gets a ClusterRole |

The golden rule is **least privilege**: grant the minimum verbs on the minimum resources. A read-only monitoring agent needs `get, list, watch` — never `create, delete,` or `*`.

**Activity — Terminal (dev):** Create a namespace and a tightly-scoped read-only Role.

```bash
kubectl create namespace dev 2>/dev/null || true

cat > /home/laborant/pod-reader.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["get", "list", "watch"]   # read-only — no create/update/delete
EOF

kubectl apply -f /home/laborant/pod-reader.yaml
kubectl -n dev describe role pod-reader
```

::hint-box
---
:summary: How do I test what a Role actually allows?
---
`kubectl auth can-i` is your friend. After binding the role to a subject you can ask, for example, `kubectl auth can-i delete pods --namespace dev --as system:serviceaccount:dev:reader`. It answers `yes`/`no` without you having to actually attempt the action. Auditing RBAC with `can-i` is how you catch an over-broad grant before an attacker does.
::

::simple-task
---
:tasks: tasks
:name: verify_role_created
---
#active
Create a `pod-reader` Role in the `dev` namespace.

#completed
The Role exists. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_least_privilege
---
#active
Ensure `pod-reader` only grants `get`, `list`, `watch` — no write or wildcard verbs.

#completed
The Role follows least privilege. ✓
::

---

## 2. Store and read a secret from Vault (dev mode)

The lab runs a dev-mode Vault on `http://127.0.0.1:8200` with a known root token (dev mode only!). You'll write a secret and read it back — the workflow an app would use instead of hard-coding the value.

**Activity — Terminal (dev):** Put a database password into Vault and read it back.

```bash
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'   # dev-mode root token — NEVER do this in production

# Store a secret
vault kv put secret/myapp db_password='S3cr3t-from-vault'

# Read it back and save proof
vault kv get secret/myapp | tee /home/laborant/vault-read.txt
```

::hint-box
---
:summary: What does an app gain by fetching this at runtime instead of baking it in?
---
Three things. **Rotation:** change the value in Vault and every app picks up the new one — no redeploy, no image rebuild. **Revocation and audit:** Vault logs who read what and when, and you can cut access instantly. **Dynamic secrets:** Vault can generate a *short-lived* database credential per request that auto-expires, so a leaked value is useless within minutes. None of that is possible when the password is a string in your YAML.
::

::simple-task
---
:tasks: tasks
:name: verify_vault_secret
---
#active
Store a secret in the dev-mode Vault and save the read-back output to `/home/laborant/vault-read.txt`.

#completed
You read a secret from Vault. ✓
::

Finally, confirm the cluster is reachable and record the node list so the lab can confirm you ran this step:

```bash
# tee records the node list so the lab can confirm YOU ran this step
kubectl get nodes | tee /home/laborant/cluster-check.txt
```

::simple-task
---
:tasks: tasks
:name: verify_cluster
---
#active
Confirm the cluster is reachable with `kubectl get nodes` — the check records it to `/home/laborant/cluster-check.txt`.

#completed
Cluster is ready. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **RBAC** | Role-Based Access Control — bounds what a subject can do |
| **Role / ClusterRole** | Define allowed verbs on resources (namespace / cluster) |
| **RoleBinding** | Grants a Role to a user, group, or service account |
| **Least privilege** | Grant the minimum verbs on the minimum resources |
| **`kubectl auth can-i`** | Test what a subject is allowed to do |
| **Kubernetes Secret** | Base64-encoded, not encrypted by default |
| **Vault (dev mode)** | In-memory secrets manager for learning; never for prod |
| **Dynamic secret** | Short-lived, auto-expiring credential generated on demand |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**RBAC y gestión de secretos**

- El daño que puede hacer un workload comprometido está acotado por **lo que tenía permitido hacer**. El **RBAC** define ese límite: concede el *mínimo privilegio* (verbos mínimos sobre recursos mínimos).
- Objetos RBAC: `Role`/`ClusterRole` (qué se permite) y `RoleBinding`/`ClusterRoleBinding` (a quién). Prueba los permisos con `kubectl auth can-i`.
- Los **Secrets** de Kubernetes solo están en base64, **no cifrados**. Para credenciales reales usa un gestor como **Vault**: cifrado, políticas de acceso, rotación, secretos dinámicos de corta vida y auditoría (OWASP K8s **K08**).
- Usamos Vault en **modo dev** (`vault server -dev`): en memoria, auto-unsealed, ligero para el microVM — **nunca en producción**. OpenBao (MPL-2.0) es la alternativa open source.
- Creaste un `Role` de solo lectura (`get/list/watch`) y leíste un secreto de Vault.
::

---

## Now Prove It

The challenge asks you to design least-privilege RBAC for a monitoring service account and store its credentials in Vault instead of a manifest.

::card
---
:challenge: challenges.k8s-rbac-a7d48c0f
---
::
