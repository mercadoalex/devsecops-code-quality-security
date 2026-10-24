---
kind: lesson

title: Your First Vulnerability Scan with Trivy
description: |
  Scan a container image for known CVEs, read a Trivy report, understand
  severity levels, and fail a build on critical findings — the first automated
  security gate of the course.

name: trivy-first-scan
slug: trivy-first-scan

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security

tagz:
- trivy
- cve
- devsecops

playground:
  name: devsecops-base-c07e1a31

challenges:
  trivy-first-scan-26cd5ac1: {}

tasks:
  verify_image_pulled:
    machine: dev-machine
    user: laborant
    run: |
      if ! docker image inspect python:3.9-slim >/dev/null 2>&1; then
        echo "python:3.9-slim image not present"
        exit 1
      fi
      echo "image present"
    hintcheck: |
      if ! docker image inspect python:3.9-slim >/dev/null 2>&1; then
        echo "Pull the scan target first:  docker pull python:3.9-slim"
      fi

  verify_scan_report:
    machine: dev-machine
    user: laborant
    needs:
      - verify_image_pulled
    run: |
      FILE=/home/laborant/trivy-report.json
      if [ ! -f "${FILE}" ]; then
        echo "trivy-report.json not found"
        exit 1
      fi
      if ! grep -qi "Vulnerabilities\|CVE-" "${FILE}"; then
        echo "report does not look like Trivy JSON output"
        exit 1
      fi
      echo "scan report present"
    hintcheck: |
      FILE=/home/laborant/trivy-report.json
      if [ ! -f "${FILE}" ]; then
        echo "Generate the report:  trivy image -f json -o ${FILE} python:3.9-slim"
      fi

  verify_gate_script:
    machine: dev-machine
    user: laborant
    needs:
      - verify_scan_report
    run: |
      FILE=/home/laborant/gate.sh
      if [ ! -f "${FILE}" ]; then
        echo "gate.sh not found"
        exit 1
      fi
      if ! grep -qi "CRITICAL" "${FILE}"; then
        echo "gate.sh should reference CRITICAL severity"
        exit 1
      fi
      echo "gate script present"
    hintcheck: |
      FILE=/home/laborant/gate.sh
      if [ ! -f "${FILE}" ]; then
        echo "Create a gate.sh that fails when CRITICAL vulnerabilities are found."
      fi

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_gate_script
    run: |
      echo "Lesson complete — well done!"
---
