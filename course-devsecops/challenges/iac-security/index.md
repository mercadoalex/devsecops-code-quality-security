---
kind: challenge

title: 'Remediate IaC Misconfigurations'

description: |
  A provided OpenTofu file and Kubernetes manifest fail an IaC scan on real
  misconfigurations — a public bucket, an open SSH port, a privileged root
  container, and missing resource limits. Fix every finding so both Checkov and
  trivy config pass clean. Nothing is deployed; this is static analysis only.

categories:
  - security
  - ci-cd

tagz:
  - checkov
  - opentofu
  - misconfiguration
  - devsecops

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-0d12f62a

tasks:
  verify_no_public_bucket:
    machine: dev-machine
    user: laborant
    run: |
      FILE=/home/laborant/iac/main.tf
      if [ ! -f "${FILE}" ]; then
        echo "iac/main.tf not found"
        exit 1
      fi
      if grep -qi "public-read\|public-read-write" "${FILE}"; then
        echo "The bucket ACL is still public"
        exit 1
      fi
      echo "bucket not public"

  verify_no_open_ssh:
    machine: dev-machine
    user: laborant
    needs:
      - verify_no_public_bucket
    run: |
      FILE=/home/laborant/iac/main.tf
      if grep -A3 "from_port *= *22" "${FILE}" | grep -q "0.0.0.0/0"; then
        echo "SSH (port 22) is still open to 0.0.0.0/0"
        exit 1
      fi
      echo "ssh not world-open"

  verify_pod_hardened:
    machine: dev-machine
    user: laborant
    needs:
      - verify_no_open_ssh
    run: |
      FILE=/home/laborant/iac/pod.yaml
      if [ ! -f "${FILE}" ]; then
        echo "iac/pod.yaml not found"
        exit 1
      fi
      if grep -qi "privileged:[[:space:]]*true" "${FILE}"; then
        echo "Container is still privileged"
        exit 1
      fi
      if grep -qi "runAsNonRoot:[[:space:]]*false" "${FILE}"; then
        echo "Container still allows running as root"
        exit 1
      fi
      if ! grep -qi "limits:" "${FILE}"; then
        echo "No resource limits set on the container"
        exit 1
      fi
      echo "pod hardened"

  verify_trivy_config_clean:
    machine: dev-machine
    user: laborant
    needs:
      - verify_pod_hardened
    run: |
      if ! trivy config --exit-code 1 --severity CRITICAL,HIGH /home/laborant/iac >/dev/null 2>&1; then
        echo "trivy config still reports HIGH/CRITICAL misconfigurations"
        exit 1
      fi
      echo "trivy config clean on HIGH/CRITICAL"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_trivy_config_clean
    run: |
      echo "Challenge complete!"
---

## Fix every misconfiguration

The files in `/home/laborant/iac/` fail an IaC scan. Remediate all of them so
`trivy config` reports no HIGH/CRITICAL findings:

1. **`main.tf`** — make the S3 bucket ACL **private**, and restrict SSH (port 22)
   to a specific CIDR instead of `0.0.0.0/0`.
2. **`pod.yaml`** — remove `privileged: true`, set `runAsNonRoot: true`, and add
   CPU/memory **requests and limits**.
3. Re-scan with `trivy config` (and `checkov -d`) until the HIGH/CRITICAL
   findings are gone.

> Remember: nothing is deployed. You are editing text files and re-scanning them.

::hint-box
---
:summary: The fixes at a glance
---
```hcl
acl = "private"                    # was public-read
cidr_blocks = ["10.0.0.0/16"]      # was 0.0.0.0/0
```
```yaml
securityContext:
  privileged: false
  runAsNonRoot: true
resources:
  requests: { cpu: "100m", memory: "128Mi" }
  limits:   { cpu: "500m", memory: "256Mi" }
```
::

::simple-task
---
:tasks: tasks
:name: verify_no_public_bucket
---
#active
Make the S3 bucket ACL private.

#completed
Bucket is no longer public. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_no_open_ssh
---
#active
Restrict SSH so port 22 is not open to `0.0.0.0/0`.

#completed
SSH is no longer world-open. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_pod_hardened
---
#active
Remove privileged, set runAsNonRoot, and add resource limits to the pod.

#completed
Pod manifest hardened. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_trivy_config_clean
---
#active
Re-scan with `trivy config` until no HIGH/CRITICAL misconfigurations remain.

#completed
IaC scan is clean. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you remediated the infrastructure before it shipped.

#completed
IaC security challenge complete. ✓
::
