---
kind: lesson

title: Secret Scanning with Gitleaks
description: |
  Why leaked credentials are the most common real breach vector, how secrets
  hide in Git history even after you delete them, and how to scan a repository
  and wire a pre-commit hook that stops secrets before they are ever committed.

name: secret-scanning-gitleaks
slug: secret-scanning-gitleaks

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- ci-cd

tagz:
- gitleaks
- secrets
- git
- devsecops

playground:
  name: devsecops-base-c07e1a31

challenges:
  gitleaks-scan-6d67fce8: {}

tasks:
  verify_gitleaks:
    machine: dev-machine
    user: laborant
    run: |
      if ! command -v gitleaks >/dev/null 2>&1; then
        echo "gitleaks not found"
        exit 1
      fi
      echo "gitleaks ok"
    hintcheck: |
      echo "Confirm Gitleaks:  gitleaks version"

  verify_repo:
    machine: dev-machine
    user: laborant
    needs:
      - verify_gitleaks
    run: |
      if [ ! -d /home/laborant/leaky-repo/.git ]; then
        echo "leaky-repo is not a git repository"
        exit 1
      fi
      echo "repo ok"
    hintcheck: |
      echo "Create a git repo at /home/laborant/leaky-repo with a committed secret."

  verify_detect_report:
    machine: dev-machine
    user: laborant
    needs:
      - verify_repo
    run: |
      FILE=/home/laborant/gitleaks-report.json
      if [ ! -f "${FILE}" ]; then
        echo "gitleaks-report.json not found"
        exit 1
      fi
      echo "report present"
    hintcheck: |
      echo "Scan history:  gitleaks detect -s /home/laborant/leaky-repo -r /home/laborant/gitleaks-report.json"

  verify_precommit_hook:
    machine: dev-machine
    user: laborant
    needs:
      - verify_repo
    run: |
      HOOK=/home/laborant/leaky-repo/.git/hooks/pre-commit
      if [ ! -f "${HOOK}" ]; then
        echo "pre-commit hook not found"
        exit 1
      fi
      if ! grep -qi "gitleaks" "${HOOK}"; then
        echo "pre-commit hook does not run gitleaks"
        exit 1
      fi
      echo "hook ok"
    hintcheck: |
      echo "Add a .git/hooks/pre-commit that runs 'gitleaks protect --staged'."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_detect_report
      - verify_precommit_hook
    run: |
      echo "Lesson complete — well done!"
---
