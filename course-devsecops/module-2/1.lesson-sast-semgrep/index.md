---
kind: lesson

title: Static Analysis (SAST) with Semgrep
description: |
  Run static application security testing against a code base with Semgrep,
  read the findings, understand the difference between bugs, vulnerabilities and
  code smells, and turn a scan into a gate that blocks a merge on new problems.

name: static-analysis-semgrep
slug: static-analysis-semgrep

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- programming

tagz:
- semgrep
- sast
- code-quality
- devsecops

playground:
  name: devsecops-base-0d12f62a

challenges:
  semgrep-gate-04bd1d49: {}

tasks:
  verify_semgrep_installed:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient PATH,
      # so this task only turns green after the learner actually checks the version.
      FILE=/home/laborant/semgrep-version.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the version check in the Terminal (dev) tab"
        exit 1
      fi
      if ! grep -qE "[0-9]+\.[0-9]+|[0-9]" "${FILE}"; then
        echo "${FILE} does not look like a version string — re-run the check"
        exit 1
      fi
      # Double-check Semgrep really is on PATH (the marker could be stale).
      if ! command -v semgrep >/dev/null 2>&1; then
        echo "semgrep not found on PATH"
        exit 1
      fi
      echo "semgrep present and confirmed by the student"
    hintcheck: |
      echo "Run this exact command in the Terminal (dev) tab:"
      echo "  semgrep --version | tee /home/laborant/semgrep-version.txt"

  verify_project_created:
    machine: dev-machine
    user: laborant
    needs:
      - verify_semgrep_installed
    run: |
      FILE=/home/laborant/project/src/app.py
      if [ ! -f "${FILE}" ]; then
        echo "project source not found"
        exit 1
      fi
      echo "project present"
    hintcheck: |
      echo "Create the demo project at /home/laborant/project/src/app.py"

  verify_scan_report:
    machine: dev-machine
    user: laborant
    needs:
      - verify_project_created
    run: |
      FILE=/home/laborant/semgrep-report.json
      if [ ! -f "${FILE}" ]; then
        echo "semgrep-report.json not found"
        exit 1
      fi
      if ! grep -qi "results\|check_id\|errors" "${FILE}"; then
        echo "report does not look like Semgrep JSON output"
        exit 1
      fi
      echo "scan report present"
    hintcheck: |
      echo "Generate it:  semgrep scan --config auto --json -o /home/laborant/semgrep-report.json /home/laborant/project"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_scan_report
    run: |
      echo "Lesson complete — well done!"
---
