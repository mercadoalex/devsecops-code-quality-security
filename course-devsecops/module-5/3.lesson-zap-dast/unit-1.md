---
kind: unit

title: Dynamic Testing (DAST) with OWASP ZAP

name: dast-owasp-zap-unit-1
---

## SAST reads the blueprint; DAST rattles the doors

Static analysis (Semgrep, SonarQube) reads your source code and reasons about what *could* go wrong. But some vulnerabilities only exist in the *running* system: a missing security header, a misconfigured cookie, an auth bypass that depends on how the server is deployed, an injection that only triggers against the live database. No amount of reading the code reveals these — you have to interact with the running app.

That is **DAST** — Dynamic Application Security Testing. A DAST tool treats your app as a black box, crawls it, and fires real malicious requests at it, then reports what got through. **OWASP ZAP** (Zed Attack Proxy) is the leading open-source DAST tool, and its **baseline scan** is built for exactly one thing: a fast, headless, pass/fail security check you can drop into CI.

::image-box
---
:src: __static__/dast-vs-sast-v1.png
:alt: Split diagram. Left "SAST" shows a magnifying glass over source-code files, labelled "reads the code, before running". Right "DAST" shows OWASP ZAP sending HTTP attack requests (XSS payload, header checks, injection) at a running web app and reading the responses, labelled "attacks the running app, black box". A center note reads "complementary — run both"
---
_SAST analyzes the code at rest; DAST attacks the app in motion. They find different classes of bug, so mature pipelines run both._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tool:** OWASP ZAP (Apache 2.0), run as the headless **baseline scan** (`zap-baseline.py`, shipped in the ZAP container)
- **Why it fits our microVM:** the full ZAP desktop GUI is heavy (Java, ~1 GB+), so we never launch it. The baseline scan is a short, headless passive crawl against one URL with a bounded time budget — it fits a 2 GiB VM when run against a small local target.
- **Playground:** `devsecops-base`.
::

::hint-box
---
:summary: Baseline scan vs full active scan — what's the difference?
---
The **baseline** scan is mostly *passive*: ZAP spiders the app and inspects the traffic for issues (missing headers, insecure cookies, information leaks) without hammering it with attacks. It's fast (a minute or two) and safe to run against any environment — ideal for CI on every build. The **full active** scan actively injects attack payloads (SQLi, XSS) and can take a long time and alter data — you run it less often, against a dedicated test environment. For a microVM and a teaching lab, the baseline scan is the right tool.
::

---

## 1. Start a target app

**Activity — Terminal (dev):** Confirm a target web app is running to scan. The lab's demo app **auto-starts on port 8080**.

```bash
# The demo app auto-starts on :8080 — confirm it responds (expect 200)
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/
```

If it isn't up for any reason, start it yourself:

```bash
# Only needed if port 8080 is not already responding:
docker run -d -p 8080:80 --name demo-app vuln-app:latest 2>/dev/null || true
```

::simple-task
---
:tasks: tasks
:name: verify_target_up
---
#active
Start the target app and confirm `http://localhost:8080/` returns HTTP 200.

#completed
The scan target is running. ✓
::

---

## 2. Run the ZAP baseline scan

**Activity — Terminal (dev):** Run the headless baseline scan against the target and save an HTML report.

```bash
# Run ZAP's baseline scan from the official container, headless.
# --network host lets the container reach localhost:8080 on the VM.
# -I = do not fail the shell on warnings (we read the report instead);
# -m 2 caps the passive-scan time to ~2 minutes.
docker run --rm --network host \
  -v /home/laborant:/zap/wrk:rw \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:8080 -r zap-report.html -m 2 -I

ls -la /home/laborant/zap-report.html
```

> ⏱️ The baseline scan typically takes 1–3 minutes. The `-m 2` flag bounds it.

::hint-box
---
:summary: Why --network host, and what do the alerts mean?
---
`--network host` makes the ZAP container share the VM's network so it can hit `localhost:8080` directly. ZAP reports **alerts** at risk levels (High / Medium / Low / Informational). On a typical app you'll see things like *missing Content-Security-Policy header*, *cookie without HttpOnly/Secure flags*, or *X-Content-Type-Options not set* — exactly the runtime hardening gaps SAST can't see. Each alert links to an explanation and a fix.
::

::simple-task
---
:tasks: tasks
:name: verify_zap_report
---
#active
Run the ZAP baseline scan against the target and save `/home/laborant/zap-report.html`.

#completed
The DAST baseline scan produced a report. ✓
::

---

## 3. Triage one finding

A report nobody reads changes nothing. Pick one alert, understand it, and write down the fix — the habit that turns a scan into security.

**Activity — Terminal (dev):** Summarize one finding from the report.

```bash
cat > /home/laborant/dast-findings.md << 'EOF'
# DAST findings (OWASP ZAP baseline)

## Finding: Missing Content-Security-Policy (CSP) header
- Risk: Medium
- What ZAP saw: responses have no Content-Security-Policy header
- Why it matters: a CSP header limits where scripts/styles can load from,
  which is a strong defense-in-depth control against XSS (OWASP A03).
- Fix: have the app/reverse-proxy send a restrictive
  `Content-Security-Policy` header on all responses.
EOF

cat /home/laborant/dast-findings.md
```

::hint-box
---
:summary: How does a baseline scan become a CI gate?
---
`zap-baseline.py` returns a **non-zero exit code** when it finds alerts above your threshold (drop the `-I` flag, or use `-l` to set the fail level, e.g. `-l High`). So a CI job can run the scan on a freshly deployed preview environment and fail the pipeline if the app ships a High-risk runtime issue. You can also feed it a config file to mark known/accepted alerts as warnings instead of failures — the DAST equivalent of a baseline.
::

::simple-task
---
:tasks: tasks
:name: verify_findings_notes
---
#active
Summarize one ZAP finding (and its fix) in `/home/laborant/dast-findings.md`.

#completed
You triaged a runtime finding. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **DAST** | Dynamic Application Security Testing — attacks the running app |
| **SAST vs DAST** | Reads code at rest vs probes the app in motion (run both) |
| **OWASP ZAP** | Leading open-source DAST tool |
| **`zap-baseline.py`** | Headless, fast, passive-leaning scan for CI |
| **Active scan** | Injects attack payloads; slower, test-env only |
| **Alert risk levels** | High / Medium / Low / Informational |
| **`-l` fail level** | Exit non-zero above a risk threshold (CI gate) |
| **Common findings** | Missing CSP, insecure cookies, missing security headers |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Pruebas dinámicas (DAST) con OWASP ZAP**

- El **SAST** lee el código; el **DAST** ataca la **app en ejecución** como lo haría un atacante. Algunos fallos solo existen en el sistema corriendo: cabeceras de seguridad ausentes, cookies mal configuradas, bypass de auth según el despliegue.
- **OWASP ZAP** es el DAST open source de referencia. Su **baseline scan** (`zap-baseline.py`, headless) es rápido y pensado para CI — rastrea la app y revisa el tráfico de forma mayormente *pasiva*.
- No usamos la GUI de ZAP (pesada, ~1 GB). El baseline corre en contenedor, headless, con tiempo acotado (`-m 2`) contra un objetivo pequeño — apto para el microVM.
- El **active scan** inyecta payloads reales (SQLi, XSS): más lento y solo en entornos de prueba.
- Lanzaste un objetivo, ejecutaste el baseline, guardaste el reporte y documentaste un hallazgo (p. ej. falta de cabecera CSP) con su solución. Con `-l High` el scan falla el pipeline por hallazgos de riesgo alto.
::

---

## Now Prove It

The challenge asks you to scan a running target with ZAP's baseline, save the report, and document a specific finding with a concrete remediation.

::card
---
:challenge: challenges.zap-dast-1ea402e5
---
::
