---
kind: lesson

title: Technical Debt & "Clean as You Code"
description: |
  Measure technical debt, understand maintainability ratings, and apply the
  "clean as you code" strategy with a Semgrep baseline so new code meets your
  standard while legacy debt is paid down opportunistically.

name: technical-debt-clean-as-you-code
slug: technical-debt-clean-as-you-code

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- programming

tagz:
- semgrep
- code-quality
- technical-debt
- devsecops

playground:
  name: devsecops-base-c07e1a31

challenges:
  tech-debt-562e044d: {}

tasks:
  verify_semgrep:
    machine: dev-machine
    user: laborant
    run: |
      if ! command -v semgrep >/dev/null 2>&1; then
        echo "semgrep not installed"
        exit 1
      fi
      echo "semgrep ok"
    hintcheck: |
      echo "Confirm Semgrep:  semgrep --version"

  verify_baseline:
    machine: dev-machine
    user: laborant
    needs:
      - verify_semgrep
    run: |
      FILE=/home/laborant/project/.semgrep-baseline.json
      if [ ! -f "${FILE}" ]; then
        echo "baseline not found"
        exit 1
      fi
      echo "baseline present"
    hintcheck: |
      echo "Create a baseline of existing findings so only NEW findings gate the build."

  verify_gate_definition:
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
      if ! grep -qi "new\|baseline" "${FILE}"; then
        echo "quality-gate.json should describe a policy that targets NEW code"
        exit 1
      fi
      echo "gate definition present"
    hintcheck: |
      echo "Describe your gate policy in /home/laborant/quality-gate.json, focused on new code."

  verify_debt_notes:
    machine: dev-machine
    user: laborant
    needs:
      - verify_gate_definition
    run: |
      FILE=/home/laborant/debt-plan.md
      if [ ! -f "${FILE}" ]; then
        echo "debt-plan.md not found"
        exit 1
      fi
      if ! grep -qi "clean as you code\|new code\|legacy\|debt" "${FILE}"; then
        echo "debt-plan.md should describe a clean-as-you-code strategy"
        exit 1
      fi
      echo "debt plan present"
    hintcheck: |
      echo "Write /home/laborant/debt-plan.md describing a clean-as-you-code strategy."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_debt_notes
    run: |
      echo "Lesson complete — well done!"
---
