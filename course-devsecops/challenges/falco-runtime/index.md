---
kind: challenge

title: 'Catch an Intrusion with Falco'

description: |
  Trigger a runtime alert by spawning a shell in a container, capture the Falco
  alert, and write a custom rule that detects a suspicious binary running inside
  a container. Prove you can see and describe live threats.

categories:
  - security
  - observability

tagz:
  - falco
  - runtime
  - threat-detection
  - devsecops

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-k8s-1ae0b5be

tasks:
  verify_falco:
    machine: dev-machine
    user: laborant
    run: |
      if ! pgrep -x falco >/dev/null 2>&1 && ! systemctl is-active --quiet falco 2>/dev/null; then
        echo "Falco is not running"
        exit 1
      fi
      echo "falco ok"

  verify_alert:
    machine: dev-machine
    user: laborant
    needs:
      - verify_falco
    run: |
      FILE=/home/laborant/intrusion-alert.txt
      if [ ! -f "${FILE}" ]; then
        echo "intrusion-alert.txt not found"
        exit 1
      fi
      if ! grep -qiE "shell|container|warning|notice" "${FILE}"; then
        echo "intrusion-alert.txt does not contain a Falco alert"
        exit 1
      fi
      echo "alert captured"

  verify_rule:
    machine: dev-machine
    user: laborant
    needs:
      - verify_falco
    run: |
      FILE=/home/laborant/custom-rule.yaml
      if [ ! -f "${FILE}" ]; then
        echo "custom-rule.yaml not found"
        exit 1
      fi
      for k in "rule:" "condition:" "output:" "priority:"; do
        if ! grep -qi "${k}" "${FILE}"; then
          echo "custom-rule.yaml is missing ${k}"
          exit 1
        fi
      done
      echo "rule ok"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_alert
      - verify_rule
    run: |
      echo "Challenge complete!"
---

## See the intrusion

1. Make sure Falco is running.
2. Spawn a shell inside a running container and capture the resulting Falco
   alert to `/home/laborant/intrusion-alert.txt`.
3. Write a custom rule at `/home/laborant/custom-rule.yaml` with all four parts
   — `rule:`, `condition:`, `output:`, `priority:` — that detects a suspicious
   binary (for example `nc`/`netcat` or `curl`) executing inside a container.

::hint-box
---
:summary: Starter commands and rule shape
---
```bash
docker run -d --name victim nginx:stable
docker exec victim bash -c "id"
sudo journalctl -u falco --no-pager | grep -i shell | tail -n 3 > /home/laborant/intrusion-alert.txt
```
```yaml
- rule: Suspicious tool in container
  desc: Detect network tools launched inside a container
  condition: container and proc.name in (nc, ncat, netcat, curl)
  output: "Suspicious tool run (proc=%proc.name container=%container.name user=%user.name)"
  priority: WARNING
  tags: [network, mitre_execution]
```
::

::simple-task
---
:tasks: tasks
:name: verify_falco
---
#active
Confirm Falco is running.

#completed
Falco is up. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_alert
---
#active
Trigger and capture a Falco alert to `intrusion-alert.txt`.

#completed
Alert captured. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_rule
---
#active
Write a complete custom rule to `custom-rule.yaml`.

#completed
Custom rule written. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you can detect and describe live threats.

#completed
Falco challenge complete. ✓
::
