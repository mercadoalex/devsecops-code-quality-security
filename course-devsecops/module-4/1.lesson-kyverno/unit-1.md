---
kind: unit

title: Policy-as-Code with Kyverno

name: policy-as-code-kyverno-unit-1
---

## The best time to stop a bad pod is before it starts

In the last module you *scanned* a privileged pod manifest and fixed it. But scanning relies on someone running the scan. What stops a teammate from applying a privileged pod straight to the cluster at 2 a.m.? The answer is **admission control**: a gate inside Kubernetes itself that inspects every object *as it is created* and can reject the ones that break your rules.

**Kyverno** is a policy engine that plugs into that gate. You write policies as Kubernetes YAML — no new language to learn — and Kyverno enforces them on every `kubectl apply`. A policy like "no privileged containers" means a privileged pod is *refused at the door*, regardless of who submits it or when.

::image-box
---
:src: __static__/kyverno-admission-v1.png
:alt: Diagram of a kubectl apply request flowing to the Kubernetes API server, which calls out to a Kyverno admission webhook; Kyverno evaluates the object against ClusterPolicies and returns allow or deny; an allowed object is written to etcd and scheduled, a denied object is rejected with an error message shown back to the user, who never sees the pod created
---
_Kyverno sits in the admission path: every create/update is checked against your policies before the object is ever persisted._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tools:** Kyverno (Apache 2.0) on single-node **k3s** (Apache 2.0), driven with `kubectl`
- **Why it fits our microVM:** k3s is a lightweight Kubernetes distribution designed for small nodes; a single-node cluster plus Kyverno runs in the 4 GiB `devsecops-k8s` playground.
- **Alternative:** OPA Gatekeeper + Rego (Apache 2.0) does policy-as-code too; Kyverno is chosen here because policies are plain YAML, which is gentler to learn.
- **Playground:** `devsecops-k8s`.
::

::hint-box
---
:summary: Isn't this the same as the Pod Security Standards built into Kubernetes?
---
Related, but more flexible. Kubernetes ships **Pod Security Admission** with three fixed profiles (privileged / baseline / restricted). That is a great baseline. Kyverno goes further: you write *custom* rules ("images must come from our registry", "every pod must have resource limits", "deny the `latest` tag"), you can *mutate* objects to add safe defaults, and you can *generate* companion resources. Use Pod Security Standards for the coarse profile and Kyverno for everything specific to your organization.
::

---

## 1. The OWASP Kubernetes Top 10

Just as web apps have the OWASP Top 10, Kubernetes has its own. These are the risks Kyverno policies most often address:

| ID | Risk |
|---|---|
| K01 | Insecure workload configurations (privileged, root, no limits) |
| K02 | Supply chain vulnerabilities (unverified images) |
| K03 | Overly permissive RBAC |
| K04 | Lack of centralized policy enforcement |
| K05 | Inadequate logging and monitoring |
| K06 | Broken authentication |
| K07 | Missing network segmentation controls |
| K08 | Secrets management failures |
| K09 | Misconfigured cluster components |
| K10 | Outdated and vulnerable Kubernetes components |

This lesson tackles **K01** (insecure workload config) and **K04** (centralized policy enforcement). The next lesson tackles **K03** (RBAC) and **K08** (secrets).

---

## 2. Confirm the cluster and Kyverno

**Activity — Terminal (dev):** Check the single-node cluster and that Kyverno is running.

```bash
# The lab runs a single-node k3s cluster
kubectl get nodes

# Kyverno is pre-installed in its own namespace
kubectl -n kyverno get pods
```

> ⏱️ On a fresh playground the Kyverno pods can take 30–60 seconds to become Ready.

::simple-task
---
:tasks: tasks
:name: verify_cluster_ready
---
#active
Run `kubectl get nodes` and confirm the k3s node is Ready.

#completed
The cluster is ready. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_kyverno_installed
---
#active
Confirm Kyverno pods are running in the `kyverno` namespace.

#completed
Kyverno is installed and running. ✓
::

---

## 3. Write a "disallow privileged" ClusterPolicy

A Kyverno policy is a YAML object. This one *validates* every Pod and *denies* any that sets `privileged: true`.

::hint-box
---
:summary: New to the terminal? Read this once (applies to every paste in this course).
---
Some activities paste a multi-line block into the terminal. **Copy the whole block at once** (from the first line through the final `EOF`) and press Enter — it runs as a single step. If your terminal ends up showing a lonely `>` on a new line, it's just waiting for the rest of an unfinished command: press **Ctrl + C** to cancel and paste the full block again. You can't break anything, and you can always re-run a step.
::

**Activity — Terminal (dev):** Create and apply the policy in enforce mode.

```bash
cat > /home/laborant/disallow-privileged.yaml << 'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-privileged
spec:
  validationFailureAction: Enforce   # Enforce = block; Audit = warn only
  background: true
  rules:
    - name: no-privileged-containers
      match:
        any:
          - resources:
              kinds:
                - Pod
      validate:
        message: "Privileged containers are not allowed."
        pattern:
          spec:
            =(securityContext):
              =(privileged): "false"
            containers:
              - =(securityContext):
                  =(privileged): "false"
EOF

kubectl apply -f /home/laborant/disallow-privileged.yaml
kubectl get clusterpolicy disallow-privileged
```

::hint-box
---
:summary: What do =( ) and the "false" strings mean in that pattern?
---
Kyverno's `pattern` is a declarative match. The `=( )` wrapper means "if this field is present, it must match" — so the rule only fires when `privileged` is actually set, and requires it to be `false`. Writing `"false"` as a string is a Kyverno pattern convention. The upshot: any Pod that sets `privileged: true` fails validation and, because `validationFailureAction: Enforce` is set, is rejected outright.
::

::hint-box
---
:summary: Enforce vs Audit — which should I ship first?
---
Start in **Audit**. Audit mode records policy violations as reports without blocking anything, so you can see what *would* break before you turn on enforcement. Once the reports are clean (or you've fixed the offenders), switch to **Enforce**. Flipping straight to Enforce on a live cluster can block legitimate deployments you didn't know violated the rule. Audit-then-enforce is the safe rollout.
::

::simple-task
---
:tasks: tasks
:name: verify_policy_applied
---
#active
Create and apply the `disallow-privileged` ClusterPolicy in Enforce mode.

#completed
The policy is applied to the cluster. ✓
::

---

## 4. Prove it blocks a privileged pod

**Activity — Terminal (dev):** Try to create a privileged pod. Kyverno should refuse it.

```bash
# This should be DENIED by the admission webhook
kubectl run badpod --image=nginx --privileged --dry-run=server
# Expect an error mentioning disallow-privileged / not allowed
```

::simple-task
---
:tasks: tasks
:name: verify_privileged_blocked
---
#active
Attempt to create a privileged pod and confirm Kyverno **denies** it.

#completed
Privileged pods are blocked at admission. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **Admission control** | Kubernetes gate that inspects objects as they are created |
| **Kyverno** | Policy engine; policies are plain Kubernetes YAML |
| **ClusterPolicy** | A cluster-wide Kyverno policy |
| **validate / mutate / generate** | Kyverno rule types: block, add defaults, create companions |
| **Enforce vs Audit** | Block violations vs record them without blocking |
| **OWASP K8s Top 10** | The ten most critical Kubernetes risk categories |
| **Pod Security Admission** | Built-in coarse profiles (privileged/baseline/restricted) |
| **`--dry-run=server`** | Ask the API server (and webhooks) to validate without persisting |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Policy-as-code con Kyverno**

- El mejor momento para frenar un pod inseguro es **antes de que arranque**. El **control de admisión** es una puerta dentro de Kubernetes que inspecciona cada objeto al crearse y puede rechazarlo.
- **Kyverno** es un motor de políticas que se conecta a esa puerta. Escribes las políticas como YAML de Kubernetes (sin lenguaje nuevo) y se aplican en cada `kubectl apply`.
- El **OWASP Kubernetes Top 10** lista los riesgos clave; esta lección cubre **K01** (configuración insegura de workloads) y **K04** (enforcement centralizado).
- Escribiste una `ClusterPolicy` que deniega contenedores `privileged` y comprobaste que Kyverno bloquea un pod privilegiado.
- Despliega primero en **Audit** (solo reporta) y luego en **Enforce** (bloquea) — así ves qué se rompería antes de activar el bloqueo. Corre sobre **k3s** de un solo nodo, ligero para el microVM.
::

---

## Now Prove It

The challenge asks you to write a Kyverno policy that requires every container to run as non-root and carry resource limits, then prove it blocks a non-compliant pod while allowing a compliant one.

::card
---
:challenge: challenges.kyverno-policy-a193dfe4
---
::
