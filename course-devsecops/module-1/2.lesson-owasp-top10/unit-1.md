---
kind: unit

title: The OWASP Top 10

name: owasp-top-10-unit-1
---

## Ten risks cause most of the breaches you read about

You do not need to memorize every attack technique ever invented. A remarkably small list covers the overwhelming majority of real-world web breaches — and the security community maintains that list for you. It is called the **OWASP Top 10**.

OWASP (the Open Worldwide Application Security Project) publishes a ranked list of the ten most critical web application security risks, refreshed every few years from real incident data. If you learn to recognize these ten patterns, you can catch most vulnerabilities before they ship.

::image-box
---
:src: __static__/owasp-top10-overview-v1.png
:alt: A ranked list graphic titled "OWASP Top 10 (2021)" showing ten numbered categories from A01 Broken Access Control at the top down to A10 Server-Side Request Forgery at the bottom, each with a small icon and a one-line description, arranged in a vertical column
---
_The OWASP Top 10 (2021 edition) — the ten risk categories every web developer should be able to recognize._
::

::hint-box
---
:summary: Is the Top 10 a checklist that makes my app "secure"?
---
No — and OWASP is explicit about this. The Top 10 is an *awareness* document. Clearing all ten does not certify your app as safe; it means you have addressed the most common classes of risk. Think of it as the floor, not the ceiling. For deeper coverage, OWASP publishes the Application Security Verification Standard (ASVS).
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tools:** a deliberately vulnerable demo web app (container) + Docker (Apache 2.0) + `curl`
- **Why it fits our microVM:** the demo app is a small container; you exploit it with plain HTTP requests — no heavy tooling.
- **Playground:** `devsecops-base`.
::

---

## 1. The 2021 Top 10 at a glance

| ID | Category | One-line meaning |
|---|---|---|
| A01 | Broken Access Control | Users can act outside their intended permissions |
| A02 | Cryptographic Failures | Sensitive data exposed due to weak or missing crypto |
| A03 | Injection | Untrusted input changes a query or command (SQLi, XSS, etc.) |
| A04 | Insecure Design | Missing or flawed security controls by design |
| A05 | Security Misconfiguration | Default creds, verbose errors, open buckets |
| A06 | Vulnerable & Outdated Components | Using libraries with known CVEs |
| A07 | Identification & Auth Failures | Broken login, weak sessions, credential stuffing |
| A08 | Software & Data Integrity Failures | Unverified updates, insecure deserialization, CI/CD tampering |
| A09 | Security Logging & Monitoring Failures | You can't detect or respond because nothing is logged |
| A10 | Server-Side Request Forgery | Server tricked into making attacker-controlled requests |

::hint-box
---
:summary: Where do SQL injection and XSS fit? They used to have their own spots.
---
In older editions (2013, 2017) Injection was A01 and had sub-entries. In 2021 OWASP consolidated injection types — SQL injection, OS command injection, and cross-site scripting (XSS) — under a single category, **A03: Injection**. The attacks did not go away; they were regrouped. You will exploit a classic SQL injection in this lesson.
::

---

## 2. Start the vulnerable demo app

The fastest way to understand a vulnerability is to exploit it in a safe sandbox. The lab ships a deliberately vulnerable web app that **starts automatically on port 8080** when the playground boots.

**Activity — Terminal (dev):** Confirm the demo app is responding.

```bash
# The vulnerable demo app auto-starts on :8080 — confirm it is serving (expect 200)
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/
```

If you get `200`, it's ready. If for any reason it isn't up yet, you can start it yourself:

```bash
# Only needed if port 8080 is not already responding:
docker run -d -p 8080:80 --name demo-app vuln-app:latest 2>/dev/null || true
```

> ⏱️ On a fresh playground the app is usually already running within a few seconds of boot.

::simple-task
---
:tasks: tasks
:name: verify_vuln_app_running
---
#active
Start the demo app and confirm `http://localhost:8080/` returns HTTP 200.

#completed
The vulnerable demo app is running on port 8080. ✓
::

---

## 3. Exploit an A03 Injection flaw

The demo app has a login form that builds its SQL query by string concatenation — the textbook injection mistake. Instead of a username it expects, we send input that rewrites the query's logic.

**Activity — Terminal (dev):** Send a classic SQL injection payload to the login endpoint.

```bash
# A classic SQL-injection payload: ' OR '1'='1 always evaluates true,
# so the WHERE clause matches every row and the login is bypassed.
# Save the response so you can record what happened.
curl -s "http://localhost:8080/login?user=admin'%20OR%20'1'='1&pass=whatever" \
  | tee /home/laborant/exploit-attempt.txt
```

If the response contains a success or a session token for `admin`, you just bypassed authentication without knowing the password.

::hint-box
---
:summary: Why does ' OR '1'='1 break the login?
---
The app builds a query like `SELECT * FROM users WHERE user='admin' AND pass='...'`. Your input closes the `user` string early and injects `OR '1'='1`, turning the condition into something that is always true. The database happily returns a row, and the app treats that as a successful login. The fix — parameterized queries — you will apply in the challenge and study in depth in Unit 2.
::

::simple-task
---
:tasks: tasks
:name: verify_exploit_run
---
#active
In the **Terminal (dev)** tab, send the injection payload above so the response is saved to `/home/laborant/exploit-attempt.txt`.

#completed
You exploited a live SQL injection — authentication bypassed. ✓
::

---

## 4. Document your finding

A finding nobody wrote down is a finding that gets re-introduced next sprint. Record what you found, which OWASP category it belongs to, and the fix.

**Activity — Terminal (dev):** Write your findings to a file. It must reference the Injection category (A03).

```bash
# Record the finding with its OWASP category
cat > /home/laborant/owasp-findings.md << 'EOF'
# OWASP findings — demo app

## Finding 1
- Category: A03 Injection (SQL injection)
- Where: /login endpoint, user parameter
- Payload: admin' OR '1'='1
- Impact: authentication bypass
- Fix: use parameterized queries / prepared statements; never concatenate input into SQL
EOF

cat /home/laborant/owasp-findings.md
```

::simple-task
---
:tasks: tasks
:name: verify_sqli_notes
---
#active
Create `/home/laborant/owasp-findings.md` and document the injection flaw, referencing OWASP **A03** (or the word "injection").

#completed
Your finding is documented with its OWASP category. ✓
::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically.

## Key concepts reference

| Concept | Detail |
|---|---|
| **OWASP** | Open Worldwide Application Security Project |
| **OWASP Top 10** | Awareness list of the ten most critical web app risks |
| **A01 Broken Access Control** | Acting outside intended permissions |
| **A03 Injection** | Untrusted input alters a query/command (SQLi, XSS, cmd injection) |
| **A06 Vulnerable Components** | Dependencies with known CVEs — scanned by Trivy |
| **SQL injection** | Injecting SQL via unparameterized input |
| **Parameterized query** | The fix: bind input as data, never as code |
| **ASVS** | OWASP Application Security Verification Standard — deeper than the Top 10 |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**El OWASP Top 10**

- OWASP publica una lista clasificada de los **diez riesgos de seguridad más críticos** en aplicaciones web, actualizada con datos reales de incidentes. Reconocer estos diez patrones te permite atrapar la mayoría de las vulnerabilidades antes de desplegarlas.
- El Top 10 es un documento de *concienciación*, no una checklist que "certifique" la seguridad.
- En el laboratorio levantaste una app vulnerable y explotaste una **inyección SQL** (categoría **A03 Injection**) con el payload clásico `' OR '1'='1`, que evade el login sin conocer la contraseña.
- La causa: construir la consulta concatenando texto. La solución: **consultas parametrizadas** (prepared statements), que verás a fondo en la Unidad 2.
- Documentaste el hallazgo con su categoría OWASP — un hallazgo sin registrar se reintroduce en el siguiente sprint.
::

---

## Now Prove It

The challenge below hands you the vulnerable app and asks you to both exploit the injection flaw and prove you understand the fix.

::card
---
:challenge: challenges.owasp-top10-1a595ab3
---
::
