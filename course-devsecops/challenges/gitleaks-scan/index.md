---
kind: challenge

title: 'Catch a Secret in Git History'

description: |
  A repository hides a credential in its history even though the working tree
  looks clean. Detect it with Gitleaks, install a pre-commit gate that blocks
  the next one, and document the mandatory rotation step.

categories:
  - security
  - ci-cd

tagz:
  - gitleaks
  - secrets
  - git
  - devsecops

difficulty: easy

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-c07e1a31

tasks:
  verify_report:
    machine: dev-machine
    user: laborant
    run: |
      FILE=/home/laborant/leaky-repo/findings.json
      if [ ! -f "${FILE}" ]; then
        echo "findings.json not found — run gitleaks detect with -r"
        exit 1
      fi
      if ! grep -qiE "AKIA|secret|RuleID|Description" "${FILE}"; then
        echo "findings.json does not contain a detected secret"
        exit 1
      fi
      echo "secret detected"

  verify_hook:
    machine: dev-machine
    user: laborant
    needs:
      - verify_report
    run: |
      HOOK=/home/laborant/leaky-repo/.git/hooks/pre-commit
      if [ ! -x "${HOOK}" ]; then
        echo "executable pre-commit hook not found"
        exit 1
      fi
      if ! grep -qi "gitleaks protect" "${HOOK}"; then
        echo "hook must run 'gitleaks protect'"
        exit 1
      fi
      echo "hook ok"

  verify_rotation_note:
    machine: dev-machine
    user: laborant
    needs:
      - verify_report
    run: |
      FILE=/home/laborant/incident.md
      if [ ! -f "${FILE}" ]; then
        echo "incident.md not found"
        exit 1
      fi
      if ! grep -qi "rotat\|revoke" "${FILE}"; then
        echo "incident.md must state the secret is rotated/revoked"
        exit 1
      fi
      echo "rotation documented"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_hook
      - verify_rotation_note
    run: |
      echo "Challenge complete!"
---

## Detect, prevent, and respond

The repo at `/home/laborant/leaky-repo` has a secret in its history. Do all three
parts of a real response:

1. **Detect** — scan the history and save findings to
   `/home/laborant/leaky-repo/findings.json`.
2. **Prevent** — install an executable `.git/hooks/pre-commit` that runs
   `gitleaks protect` to block the next secret.
3. **Respond** — write `/home/laborant/incident.md` stating that the exposed
   secret is **rotated/revoked** (not just deleted).

::hint-box
---
:summary: Commands
---
```bash
cd /home/laborant/leaky-repo
gitleaks detect -s . -r findings.json -v
printf '#!/usr/bin/env bash\ngitleaks protect --staged -v\n' > .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
printf '# Incident\nThe leaked AWS key has been REVOKED and ROTATED.\n' > /home/laborant/incident.md
```
::

::simple-task
---
:tasks: tasks
:name: verify_report
---
#active
Detect the secret and save findings to `findings.json`.

#completed
Secret detected in history. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_hook
---
#active
Install an executable pre-commit hook running `gitleaks protect`.

#completed
Pre-commit gate installed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_rotation_note
---
#active
Document rotation/revocation in `incident.md`.

#completed
Rotation documented. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — detect, prevent, respond.

#completed
Gitleaks challenge complete. ✓
::
