---
kind: challenge

title: 'Write a Kyverno Workload Hardening Policy'

description: |
  Author a Kyverno ClusterPolicy that requires every pod to run as non-root and
  declare resource limits. Prove it blocks a non-compliant pod at admission and
  admits a compliant one. Addresses OWASP Kubernetes K01.

categories:
  - security
  - kubernetes

tagz:
  - kyverno
  - policy-as-code
  - admission-control
  - devsecops

difficulty: hard

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-k8s-1ae0b5be

tasks:
  verify_policy_exists:
    machine: dev-machine
    user: laborant
    run: |
      if ! kubectl get clusterpolicy require-hardened-pods >/dev/null 2>&1; then
        echo "ClusterPolicy require-hardened-pods not found"
        exit 1
      fi
      echo "policy present"

  verify_enforce_mode:
    machine: dev-machine
    user: laborant
    needs:
      - verify_policy_exists
    run: |
      MODE=$(kubectl get clusterpolicy require-hardened-pods -o jsonpath='{.spec.validationFailureAction}' 2>/dev/null)
      if ! echo "${MODE}" | grep -qi "Enforce"; then
        echo "Policy must be in Enforce mode (got '${MODE}')"
        exit 1
      fi
      echo "enforce mode"

  verify_blocks_bad_pod:
    machine: dev-machine
    user: laborant
    needs:
      - verify_enforce_mode
    run: |
      OUT=$(kubectl run badpod --image=nginx --dry-run=server 2>&1 || true)
      if ! echo "${OUT}" | grep -qiE "require-hardened-pods|not allowed|denied|validation"; then
        echo "A pod lacking non-root/limits was not blocked"
        exit 1
      fi
      echo "bad pod blocked"

  verify_allows_good_pod:
    machine: dev-machine
    user: laborant
    needs:
      - verify_blocks_bad_pod
    run: |
      FILE=/home/laborant/good-pod.yaml
      if [ ! -f "${FILE}" ]; then
        echo "Provide a compliant /home/laborant/good-pod.yaml"
        exit 1
      fi
      if ! kubectl apply --dry-run=server -f "${FILE}" >/dev/null 2>&1; then
        echo "The compliant pod was rejected — it should pass the policy"
        exit 1
      fi
      echo "good pod admitted"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_allows_good_pod
    run: |
      echo "Challenge complete!"
---

## Enforce hardened workloads

Write a Kyverno `ClusterPolicy` named `require-hardened-pods` that, in **Enforce**
mode, requires every Pod to:

- set `securityContext.runAsNonRoot: true`, and
- declare CPU/memory **limits** on each container.

Then:

1. Apply the policy.
2. Show a non-compliant pod (`kubectl run badpod --image=nginx`) is **denied**.
3. Write a compliant `/home/laborant/good-pod.yaml` that the policy **admits**.

::hint-box
---
:summary: Skeleton for the policy and a compliant pod
---
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-hardened-pods
spec:
  validationFailureAction: Enforce
  rules:
    - name: require-nonroot-and-limits
      match: { any: [ { resources: { kinds: [Pod] } } ] }
      validate:
        message: "Pods must run as non-root and set resource limits."
        pattern:
          spec:
            securityContext:
              runAsNonRoot: true
            containers:
              - resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```
A compliant pod sets `runAsNonRoot: true` and `resources.limits`.
::

::simple-task
---
:tasks: tasks
:name: verify_policy_exists
---
#active
Create the `require-hardened-pods` ClusterPolicy.

#completed
Policy created. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_enforce_mode
---
#active
Set the policy to Enforce mode.

#completed
Policy is enforcing. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_blocks_bad_pod
---
#active
Confirm a non-compliant pod is denied at admission.

#completed
Non-compliant pod blocked. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_allows_good_pod
---
#active
Write a compliant `good-pod.yaml` the policy admits.

#completed
Compliant pod admitted. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — your policy enforces hardened workloads.

#completed
Kyverno challenge complete. ✓
::
