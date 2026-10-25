---
kind: challenge

title: 'Pass the Semgrep SAST Gate'

description: |
  A project fails its Semgrep gate on two real vulnerabilities — a SQL injection
  and a hard-coded credential. Fix both, re-scan, and bring the gate to a clean
  exit with zero ERROR-severity findings.

categories:
  - security
  - programming

tagz:
  - semgrep
  - sast
  - code-quality
  - devsecops

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-0d12f62a

tasks:
  verify_semgrep:
    machine: dev-machine
    user: laborant
    run: |
      if ! command -v semgrep >/dev/null 2>&1; then
        echo "semgrep not installed"
        exit 1
      fi
      echo "semgrep ok"

  verify_no_concat_sql:
    machine: dev-machine
    user: laborant
    needs:
      - verify_semgrep
    run: |
      FILE=/home/laborant/project/src/app.py
      if [ ! -f "${FILE}" ]; then
        echo "project source not found"
        exit 1
      fi
      if grep -qE "\"SELECT .*\"[[:space:]]*\+|'[[:space:]]*\+[[:space:]]*username" "${FILE}"; then
        echo "SQL is still built by string concatenation — use parameterized queries"
        exit 1
      fi
      echo "no concatenated SQL"

  verify_no_hardcoded_secret:
    machine: dev-machine
    user: laborant
    needs:
      - verify_no_concat_sql
    run: |
      FILE=/home/laborant/project/src/app.py
      if grep -qE "password[[:space:]]*=[[:space:]]*['\"][^'\"]+['\"]" "${FILE}"; then
        echo "A hard-coded password is still present — read it from the environment"
        exit 1
      fi
      echo "no hardcoded secret"

  verify_gate_clean:
    machine: dev-machine
    user: laborant
    needs:
      - verify_no_hardcoded_secret
    run: |
      cd /home/laborant/project || exit 1
      if ! semgrep scan --config auto --error --severity ERROR . >/dev/null 2>&1; then
        echo "Semgrep still reports ERROR-severity findings — fix them and re-scan"
        exit 1
      fi
      echo "gate clean"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_gate_clean
    run: |
      echo "Challenge complete!"
---

## Turn the gate green

The project at `/home/laborant/project` fails its Semgrep gate on two real
issues. Fix both and re-scan until the gate exits clean:

1. The SQL query in `src/app.py` is built by **string concatenation** — rewrite
   it to use a **parameterized query**.
2. A **hard-coded password** is embedded in the source — read it from an
   environment variable instead.
3. Re-run Semgrep with `--error --severity ERROR` and confirm it exits 0.

::hint-box
---
:summary: Show me the two fixes
---
Parameterized query (bind the value, don't concatenate):

```python
query = "SELECT * FROM users WHERE name = ?"
return conn.execute(query, (username,)).fetchall()
```

Read the secret from the environment:

```python
import os
password = os.environ["APP_PASSWORD"]
```

Then re-scan as a gate:

```bash
cd /home/laborant/project && semgrep scan --config auto --error --severity ERROR .
```
::

::simple-task
---
:tasks: tasks
:name: verify_semgrep
---
#active
Confirm Semgrep is installed.

#completed
Semgrep is ready. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_no_concat_sql
---
#active
Rewrite the SQL query to use a parameterized statement.

#completed
SQL injection removed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_no_hardcoded_secret
---
#active
Remove the hard-coded password; read it from the environment.

#completed
Hard-coded credential removed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_gate_clean
---
#active
Re-scan with `--error --severity ERROR` and get a clean (exit 0) result.

#completed
Semgrep gate is green. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you passed the SAST gate honestly.

#completed
Semgrep challenge complete. ✓
::
