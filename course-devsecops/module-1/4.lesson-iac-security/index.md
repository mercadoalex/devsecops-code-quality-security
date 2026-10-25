---
kind: lesson

title: Infrastructure-as-Code Security
description: |
  Catch cloud and cluster misconfigurations before they ship. Scan an OpenTofu
  file and a Kubernetes manifest with Checkov and trivy config — pure static
  analysis, nothing is deployed — then fix a public bucket, an open security
  group, and a privileged pod.

name: iac-security
slug: iac-security

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- ci-cd

tagz:
- checkov
- opentofu
- misconfiguration
- devsecops

playground:
  name: devsecops-base-0d12f62a

challenges:
  iac-security-a78880fb: {}

tasks:
  verify_tools:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient PATH,
      # so this task only turns green after the learner actually checks the tools.
      FILE=/home/laborant/iac-tools.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the version check in the Terminal (dev) tab"
        exit 1
      fi
      if ! grep -qiE "checkov|version" "${FILE}"; then
        echo "${FILE} does not look like the tool version output — re-run the check"
        exit 1
      fi
      # Double-check both scanners really are on PATH (the marker could be stale).
      if ! command -v checkov >/dev/null 2>&1; then
        echo "checkov not found"
        exit 1
      fi
      if ! command -v trivy >/dev/null 2>&1; then
        echo "trivy not found"
        exit 1
      fi
      echo "tools present and confirmed by the student"
    hintcheck: |
      echo "Run this exact block in the Terminal (dev) tab:"
      echo "  { checkov --version; trivy --version; } | tee /home/laborant/iac-tools.txt"

  verify_tf_file:
    machine: dev-machine
    user: laborant
    needs:
      - verify_tools
    run: |
      FILE=/home/laborant/iac/main.tf
      if [ ! -f "${FILE}" ]; then
        echo "iac/main.tf not found"
        exit 1
      fi
      echo "tf file present"
    hintcheck: |
      echo "Create an OpenTofu file at /home/laborant/iac/main.tf to scan."

  verify_k8s_manifest:
    machine: dev-machine
    user: laborant
    needs:
      - verify_tools
    run: |
      FILE=/home/laborant/iac/pod.yaml
      if [ ! -f "${FILE}" ]; then
        echo "iac/pod.yaml not found"
        exit 1
      fi
      if ! grep -qiE "kind:[[:space:]]*Pod|kind:[[:space:]]*Deployment" "${FILE}"; then
        echo "pod.yaml should be a Kubernetes Pod or Deployment manifest"
        exit 1
      fi
      echo "k8s manifest present"
    hintcheck: |
      echo "Create a Kubernetes manifest at /home/laborant/iac/pod.yaml to scan."

  verify_scan_output:
    machine: dev-machine
    user: laborant
    needs:
      - verify_tf_file
      - verify_k8s_manifest
    run: |
      FILE=/home/laborant/iac-scan.txt
      if [ ! -f "${FILE}" ]; then
        echo "iac-scan.txt not found"
        exit 1
      fi
      if ! grep -qiE "checkov|passed|failed|check" "${FILE}"; then
        echo "iac-scan.txt does not look like a Checkov report"
        exit 1
      fi
      echo "scan output present"
    hintcheck: |
      echo "Scan and save:  checkov -d /home/laborant/iac --compact > /home/laborant/iac-scan.txt"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_scan_output
    run: |
      echo "Lesson complete — well done!"
---
