---
kind: lesson

title: Shift-Left & DevSecOps Culture
description: |
  Why security that waits until the end fails, what Shift-Left actually means,
  and how a DevSecOps culture distributes security ownership across the whole
  team. Set up your lab and confirm your toolchain is ready.

name: shift-left-devsecops-culture
slug: shift-left-devsecops-culture

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security

tagz:
- devsecops
- shift-left
- sdlc

playground:
  name: devsecops-base-0d12f62a

tasks:
  verify_docker_ready:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient daemon state,
      # so this task only turns green after the learner actually runs the wait-loop.
      FILE=/home/laborant/docker-ready.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the wait-loop in the Terminal (dev) tab"
        exit 1
      fi
      if ! grep -qi "Docker ready" "${FILE}"; then
        echo "${FILE} does not confirm Docker is ready — re-run the wait-loop"
        exit 1
      fi
      # Double-check the daemon really is up (the marker could be stale).
      if ! docker info >/dev/null 2>&1; then
        echo "Docker daemon is not responding yet — wait a few seconds and re-run"
        exit 1
      fi
      echo "Docker is ready and confirmed by the student"
    hintcheck: |
      echo "Run this exact block in the Terminal (dev) tab:"
      echo "  until docker info >/dev/null 2>&1; do echo waiting...; sleep 3; done"
      echo "  echo 'Docker ready' | tee /home/laborant/docker-ready.txt"
      if ! docker info >/dev/null 2>&1; then
        echo "(The daemon is still warming up — the loop will wait for it.)"
      fi

  verify_first_scan:
    machine: dev-machine
    user: laborant
    needs:
      - verify_docker_ready
    run: |
      FILE=/home/laborant/first-scan.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the trivy scan to create it"
        exit 1
      fi
      # Confirm a real Trivy scan ran: the report mentions the scanned target or a
      # vulnerability/severity line. Tolerant of empty-finding and warning output.
      if ! grep -qiE "python:3\.9|Target|Vulnerabilit|CVE-|CRITICAL|HIGH|MEDIUM|LOW|Total:|Report Summary" "${FILE}"; then
        echo "first-scan.txt does not look like a Trivy report — re-run the scan"
        exit 1
      fi
      echo "first scan output present"
    hintcheck: |
      if ! command -v trivy >/dev/null 2>&1; then
        echo "Trivy is not on your PATH. Check:  which trivy ; trivy --version"
      else
        echo "Run this exact command:"
        echo "  trivy image --scanners vuln python:3.9-slim > /home/laborant/first-scan.txt 2>&1"
      fi

  verify_manifesto_file:
    machine: dev-machine
    user: laborant
    needs:
      - verify_docker_ready
    run: |
      FILE=/home/laborant/devsecops-manifesto.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} does not exist"
        exit 1
      fi
      if ! grep -qi "shift" "${FILE}"; then
        echo "The manifesto does not mention shift-left"
        exit 1
      fi
      echo "devsecops-manifesto.txt exists and mentions shift-left"
    hintcheck: |
      FILE=/home/laborant/devsecops-manifesto.txt
      if [ ! -f "${FILE}" ]; then
        echo "Create ${FILE} and write one principle that includes the word 'shift'."
      fi

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_first_scan
      - verify_manifesto_file
    run: |
      echo "Lesson complete — well done!"
---
