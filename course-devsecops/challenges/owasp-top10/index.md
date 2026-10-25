---
kind: challenge

title: 'Exploit and Fix an OWASP A03 Injection'

description: |
  A login form concatenates user input straight into a SQL query. Exploit the
  injection to bypass authentication, then prove you understand the fix by
  deploying a patched version that rejects the same payload.

categories:
  - security

tagz:
  - owasp
  - injection
  - devsecops

difficulty: easy

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-c07e1a31

tasks:
  verify_app_running:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
      if [ "${STATUS}" != "200" ]; then
        echo "Vulnerable app not running on port 8080"
        exit 1
      fi
      echo "app up"

  verify_exploit_proof:
    machine: dev-machine
    user: laborant
    needs:
      - verify_app_running
    run: |
      FILE=/home/laborant/exploit-proof.txt
      if [ ! -f "${FILE}" ]; then
        echo "exploit-proof.txt not found"
        exit 1
      fi
      if ! grep -qi "OR '1'='1" "${FILE}" && ! grep -qi "1=1" "${FILE}"; then
        echo "exploit-proof.txt must contain the injection payload you used"
        exit 1
      fi
      echo "exploit documented"

  verify_patched_app:
    machine: dev-machine
    user: laborant
    needs:
      - verify_exploit_proof
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:9090/login?user=admin'%20OR%20'1'='1&pass=x")
      if [ "${STATUS}" = "200" ]; then
        BODY=$(curl -s "http://localhost:9090/login?user=admin'%20OR%20'1'='1&pass=x")
        if echo "${BODY}" | grep -qi "token\|welcome\|success"; then
          echo "Patched app still accepts the injection payload"
          exit 1
        fi
      fi
      STATUS_UP=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/)
      if [ "${STATUS_UP}" != "200" ]; then
        echo "Patched app is not running on port 9090"
        exit 1
      fi
      echo "patched app rejects injection"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_patched_app
    run: |
      echo "Challenge complete!"
---

## Exploit and fix an injection flaw

The deliberately vulnerable app on port **8080** builds its login SQL by
concatenating the `user` parameter. Your job has three parts:

1. Confirm the vulnerable app is running on port 8080.
2. Exploit the SQL injection and save the exact payload you used to
   `/home/laborant/exploit-proof.txt`.
3. Run a **patched** version on port **9090** that uses parameterized queries,
   so the same `' OR '1'='1` payload no longer logs you in.

::hint-box
---
:summary: How do I run the patched version?
---
The demo app image is baked into the lab. Start the **patched** variant on a
second port by setting `APP_MODE=patched`:

```bash
docker run -d -p 9090:80 --name juice-fixed -e APP_MODE=patched vuln-app:latest
```

In patched mode the app binds query parameters instead of concatenating them, so
the injection payload is treated as a literal (nonexistent) username and the
login fails.
::

::simple-task
---
:tasks: tasks
:name: verify_app_running
---
#active
Start the vulnerable app and confirm it responds on port 8080.

#completed
Vulnerable app is up. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_exploit_proof
---
#active
Save the injection payload you used to `/home/laborant/exploit-proof.txt`.

#completed
Exploit payload recorded. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_patched_app
---
#active
Run the patched app on port 9090 so the `' OR '1'='1` payload no longer logs in.

#completed
The patched app rejects the injection. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you have exploited and fixed an A03 Injection flaw.

#completed
Injection challenge complete. On to container scanning! ✓
::
