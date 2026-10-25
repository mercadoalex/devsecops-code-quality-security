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
  name: devsecops-base-0d12f62a

challenges:
  owasp-top10-1a595ab3: {}

tasks:
  verify_vuln_app_running:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient app state,
      # so this task only turns green after the learner actually probes the app.
      FILE=/home/laborant/app-check.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the curl check in the Terminal (dev) tab"
        exit 1
      fi
      if ! grep -q "200" "${FILE}"; then
        echo "${FILE} does not record a 200 response — re-run the curl check"
        exit 1
      fi
      # Double-check the app really is up (the marker could be stale).
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
      if [ "${STATUS}" != "200" ]; then
        echo "Vulnerable demo app not responding on port 8080 (got ${STATUS})"
        exit 1
      fi
      echo "Vulnerable demo app is running and confirmed by the student"
    hintcheck: |
      echo "Run this exact command in the Terminal (dev) tab:"
      echo "  curl -s -o /dev/null -w '%{http_code}\\n' http://localhost:8080/ | tee /home/laborant/app-check.txt"
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
      if [ "${STATUS}" != "200" ]; then
        echo "(The demo app is still warming up — it auto-starts on :8080; wait a few seconds and re-run.)"
      fi

  verify_exploit_run:
    machine: dev-machine
    user: laborant
    needs:
      - verify_vuln_app_running
    run: |
      FILE=/home/laborant/exploit-attempt.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the injection payload and save the response"
        exit 1
      fi
      # The saved response should show the injection attempt was made
      if ! grep -qiE "OR '1'='1|1=1|admin|token|login" "${FILE}"; then
        echo "exploit-attempt.txt does not look like the injection response"
        exit 1
      fi
      echo "injection attempt recorded"
    hintcheck: |
      echo "Send the payload and save the response, e.g.:"
      echo "  curl -s \"http://localhost:8080/login?user=admin'%20OR%20'1'='1&pass=x\" | tee /home/laborant/exploit-attempt.txt"

  verify_sqli_notes:
    machine: dev-machine
    user: laborant
    needs:
      - verify_exploit_run
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
