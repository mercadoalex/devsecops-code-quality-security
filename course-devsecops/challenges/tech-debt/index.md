---
kind: challenge

title: 'Design a Clean-as-You-Code Gate'

description: |
  Capture a baseline of existing findings, define a gate that enforces standards
  on new code only, and document a debt-management plan. Prove you can keep a
  legacy base from accumulating more debt without stalling delivery.

categories:
  - security
  - programming

tagz:
  - semgrep
  - code-quality
  - technical-debt
  - devsecops

difficulty: easy

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-c07e1a31

tasks:
  verify_baseline:
    machine: dev-machine
    user: laborant
    run: |
      FILE=/home/laborant/project/.semgrep-baseline.json
      if [ ! -f "${FILE}" ]; then
        echo "baseline not found — capture existing findings first"
        exit 1
      fi
      echo "baseline ok"

  verify_gate_file:
    machine: dev-machine
    user: laborant
    needs:
      - verify_baseline
    run: |
      FILE=/home/laborant/quality-gate.json
      if [ ! -f "${FILE}" ]; then
        echo "quality-gate.json not found"
        exit 1
      fi
      if ! python3 -c "import json; json.load(open('${FILE}'))" 2>/dev/null; then
        echo "quality-gate.json is not valid JSON"
        exit 1
      fi
      if ! grep -qi "new\|baseline" "${FILE}"; then
        echo "The gate must target new/changed code against a baseline"
        exit 1
      fi
      echo "gate ok"

  verify_plan:
    machine: dev-machine
    user: laborant
    needs:
      - verify_gate_file
    run: |
      FILE=/home/laborant/debt-plan.md
      if [ ! -f "${FILE}" ]; then
        echo "debt-plan.md not found"
        exit 1
      fi
      if ! grep -qi "clean as you code" "${FILE}"; then
        echo "The plan must name the clean-as-you-code strategy"
        exit 1
      fi
      if ! grep -qi "legacy\|existing" "${FILE}"; then
        echo "The plan must say how legacy debt is handled"
        exit 1
      fi
      echo "plan ok"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_plan
    run: |
      echo "Challenge complete!"
---

## Gate the new, manage the old

Produce three artifacts in the demo project workflow:

1. `/home/laborant/project/.semgrep-baseline.json` — a baseline snapshot of the
   project's existing findings.
2. `/home/laborant/quality-gate.json` — valid JSON describing a gate that
   targets **new/changed** code against that baseline.
3. `/home/laborant/debt-plan.md` — a plan that names the **clean-as-you-code**
   strategy and states how **legacy** debt is handled.

::hint-box
---
:summary: What makes a complete answer?
---
Capture the baseline with `semgrep scan --config auto --json -o .semgrep-baseline.json .`
Your gate JSON should say new code must add no ERROR findings and no secrets,
while baseline findings are report-only. Your plan should say, in plain terms:
"new code must clear the gate; existing debt is tracked but not blocking and is
paid down when we touch the surrounding code." That is clean-as-you-code.
::

::simple-task
---
:tasks: tasks
:name: verify_baseline
---
#active
Capture `.semgrep-baseline.json` of the project's existing findings.

#completed
Baseline captured. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_gate_file
---
#active
Write a valid JSON gate targeting new code against the baseline.

#completed
Gate file is valid. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_plan
---
#active
Write `debt-plan.md` naming clean-as-you-code and how legacy debt is handled.

#completed
Debt plan complete. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you designed a sustainable debt strategy.

#completed
Technical debt challenge complete. ✓
::
