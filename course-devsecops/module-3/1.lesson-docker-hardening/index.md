---
kind: lesson

title: Docker Hardening & CVE Management
description: |
  Harden a Dockerfile against the most common container mistakes — running as
  root, bloated base images, leaked secrets — and manage the CVEs Trivy finds
  by distinguishing fixable from unfixable and applying the right remediation.

name: docker-hardening-cve
slug: docker-hardening-cve

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- containers

tagz:
- docker
- trivy
- hardening
- cve

playground:
  name: devsecops-base-0d12f62a

challenges:
  docker-hardening-5361d5e5: {}

tasks:
  verify_hardened_dockerfile:
    machine: dev-machine
    user: laborant
    run: |
      FILE=/home/laborant/hardened/Dockerfile
      if [ ! -f "${FILE}" ]; then
        echo "hardened/Dockerfile not found"
        exit 1
      fi
      if ! grep -qi "USER" "${FILE}"; then
        echo "Dockerfile should include a non-root USER instruction"
        exit 1
      fi
      echo "hardened Dockerfile present"
    hintcheck: |
      echo "Create /home/laborant/hardened/Dockerfile with a non-root USER instruction."

  verify_image_built:
    machine: dev-machine
    user: laborant
    needs:
      - verify_hardened_dockerfile
    run: |
      if ! docker image inspect hardened-app:latest >/dev/null 2>&1; then
        echo "hardened-app:latest image not built"
        exit 1
      fi
      echo "image built"
    hintcheck: |
      echo "Build it:  docker build -t hardened-app:latest /home/laborant/hardened"

  verify_runs_nonroot:
    machine: dev-machine
    user: laborant
    needs:
      - verify_image_built
    run: |
      UID_OUT=$(docker run --rm hardened-app:latest id -u 2>/dev/null || echo 0)
      if [ "${UID_OUT}" = "0" ]; then
        echo "Container still runs as root (uid 0)"
        exit 1
      fi
      echo "runs as non-root uid ${UID_OUT}"
    hintcheck: |
      echo "Add a non-root user and a USER line so 'docker run ... id -u' is not 0."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_runs_nonroot
    run: |
      echo "Lesson complete — well done!"
---
