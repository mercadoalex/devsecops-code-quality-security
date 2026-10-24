---
kind: lesson

title: The OWASP Top 10
description: |
  The ten most critical web application security risks, what each one looks
  like in real code, and how to spot them. Exploit a deliberately vulnerable
  app, then fix the flaw.

name: owasp-top-10
slug: owasp-top-10

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security

tagz:
- owasp
- injection
- devsecops

playground:
  name: devsecops-base-c07e1a31

challenges:
  owasp-top10-1a595ab3: {}

tasks:
  verify_vuln_app_running:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
      if [ "${STATUS}" != "200" ]; then
        echo "Vulnerable demo app not responding on port 8080 (got ${STATUS})"
        exit 1
      fi
      echo "Vulnerable demo app is running"
    hintcheck: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
      if [ "${STATUS}" != "200" ]; then
        echo "The demo app is not up yet. Start it with:"
        echo "  docker run -d -p 8080:80 --name juice ghcr.io/iximiuz/labs/owasp-demo:latest"
      fi

  verify_sqli_notes:
    machine: dev-machine
    user: laborant
    needs:
      - verify_vuln_app_running
    run: |
      FILE=/home/laborant/owasp-findings.md
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} does not exist"
        exit 1
      fi
      if ! grep -qiE "A0?1|injection" "${FILE}"; then
        echo "owasp-findings.md should reference the Injection category (A03) or 'injection'"
        exit 1
      fi
      echo "owasp-findings.md documents an injection finding"
    hintcheck: |
      FILE=/home/laborant/owasp-findings.md
      if [ ! -f "${FILE}" ]; then
        echo "Create ${FILE} and note the OWASP category of the flaw you found."
      fi

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_sqli_notes
    run: |
      echo "Lesson complete — well done!"
---
