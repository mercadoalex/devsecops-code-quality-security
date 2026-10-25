---
kind: lesson

title: "IaC: From Static Scan to Live Posture (Optional)"
description: |
  Optional advanced lesson. Close the loop from shift-left to runtime — apply
  OpenTofu against a local AWS emulator (moto), then scan the live emulated
  account for misconfigurations with Prowler. See why static scanning and cloud
  posture scanning catch different problems.

name: iac-runtime-moto
slug: iac-runtime-moto

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- ci-cd

tagz:
- moto
- prowler
- opentofu
- devsecops

playground:
  name: devsecops-k8s-1ae0b5be

challenges:
  iac-runtime-b4d0f1f7: {}

tasks:
  verify_tools:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient PATH,
      # so this task only turns green after the learner actually checks the stack.
      FILE=/home/laborant/rt-tools.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the version check in the Terminal (dev) tab"
        exit 1
      fi
      if [ ! -s "${FILE}" ]; then
        echo "${FILE} is empty — re-run the version check"
        exit 1
      fi
      # Double-check all three tools really are on PATH (the marker could be stale).
      for t in moto_server tofu prowler; do
        if ! command -v "$t" >/dev/null 2>&1; then
          echo "$t not found on PATH"
          exit 1
        fi
      done
      echo "tools present and confirmed by the student"
    hintcheck: |
      echo "Run this exact block in the Terminal (dev) tab:"
      echo "  { moto_server --version; tofu version; prowler --version; } | tee /home/laborant/rt-tools.txt"

  verify_moto_running:
    machine: dev-machine
    user: laborant
    needs:
      - verify_tools
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5001/ 2>/dev/null || echo 000)
      if [ "${STATUS}" = "000" ]; then
        echo "moto_server is not responding on port 5001"
        exit 1
      fi
      echo "moto up"
    hintcheck: |
      echo "Start the emulator:  moto_server -p 5001  (run in the background)"

  verify_applied:
    machine: dev-machine
    user: laborant
    needs:
      - verify_moto_running
    run: |
      FILE=/home/laborant/iac-rt/apply.log
      if [ ! -f "${FILE}" ]; then
        echo "apply.log not found — run tofu apply against moto"
        exit 1
      fi
      if ! grep -qiE "apply complete|resources: [0-9]+ added|created" "${FILE}"; then
        echo "apply.log does not show a successful apply"
        exit 1
      fi
      echo "applied"
    hintcheck: |
      echo "Point AWS endpoints at http://localhost:5001 and run 'tofu apply', saving output to iac-rt/apply.log"

  verify_prowler_report:
    machine: dev-machine
    user: laborant
    needs:
      - verify_applied
    run: |
      FILE=/home/laborant/iac-rt/prowler-report.txt
      if [ ! -f "${FILE}" ]; then
        echo "prowler-report.txt not found"
        exit 1
      fi
      if ! grep -qiE "prowler|FAIL|PASS|finding|check" "${FILE}"; then
        echo "prowler-report.txt does not look like a Prowler report"
        exit 1
      fi
      echo "posture scan present"
    hintcheck: |
      echo "Run Prowler against the moto endpoint and save output to iac-rt/prowler-report.txt"

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_prowler_report
    run: |
      echo "Lesson complete — well done!"
---
