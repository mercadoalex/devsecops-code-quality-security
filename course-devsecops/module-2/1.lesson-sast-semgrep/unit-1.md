---
kind: unit

title: Static Analysis (SAST) with Semgrep

name: static-analysis-semgrep-unit-1
---

## A tireless reviewer that reads every line before you merge

Code review is one of the best security controls you have — and the hardest to do consistently. Humans get tired, miss things, and rubber-stamp big diffs on a Friday afternoon. **Static Application Security Testing (SAST)** gives you a reviewer that never gets tired: it reads your source code without running it and flags bugs, risky patterns, and insecure constructs every single time.

The tool you will use is **Semgrep** — think of it as `grep` that understands code *structure* instead of just text. A plain `grep` for the word `password` matches it anywhere. Semgrep matches patterns in the code's syntax tree: "a SQL string built by concatenating a variable", "a hard-coded credential", "a shell call with user input". It catches the dangerous *shape* regardless of variable names or formatting.

::image-box
---
:src: __static__/sast-flow-v1.png
:alt: Diagram showing source code on the left flowing into the Semgrep CLI in the center, which applies a ruleset (OWASP, secrets, language rules) and emits a findings report on the right grouped by severity ERROR, WARNING, INFO; a gate box after the report shows a green check (exit 0, merge allowed) or a red cross (exit non-zero, merge blocked)
---
_Semgrep reads the code, matches it against rules, and emits findings — and its exit code turns the scan into a merge gate._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tool:** Semgrep OSS (CLI) — `semgrep`
- **License:** LGPL 2.1 (engine) + permissive community rules — free, no server
- **Why it fits our microVM:** a single CLI, no server, no database, no Elasticsearch. Scans a directory in seconds using ~100–300 MB RAM.
- **Enterprise reference it stands in for:** SonarQube (see the hint box below).
::

::hint-box
---
:summary: Where does SonarQube fit? Why aren't we running it here?
---
**SonarQube** is the best-known SAST *platform* — a server with dashboards, historical trends, a technical-debt model, and governance-grade quality gates. Its Community Build is free and open source, and you will almost certainly meet it on the job.

We don't run it in this lab for one practical reason: the SonarQube server wants roughly **2 GB of RAM for itself** (plus a bundled Elasticsearch). On our 2 GiB microVM, running it alongside Docker would thrash or get OOM-killed. Semgrep teaches the same SAST concepts — finding types, severities, and gating — with a footprint that fits. Everything you learn here transfers directly to SonarQube's scanner and quality gate.
::

---

## 1. The finding types every SAST tool reports

SAST tools sort findings into categories. The names differ by tool, but the ideas are universal:

| Category | Meaning | Example |
|---|---|---|
| **Bug** | Code that is demonstrably wrong | Null dereference, unreachable code |
| **Vulnerability** | A security hole an attacker can use | SQL built by concatenation, hard-coded password |
| **Code Smell** | Maintainability problem, not a defect yet | Duplicated block, over-complex function |
| **Security Hotspot** | Security-sensitive code needing human review | Use of crypto, a disabled TLS check |

Semgrep expresses severity as **ERROR / WARNING / INFO**; SonarQube uses Bug/Vulnerability/Code Smell/Hotspot. Same underlying idea — triage by how much it matters.

::hint-box
---
:summary: SAST vs the Trivy scanning I just learned — what's the difference?
---
Trivy scans *dependencies and images* — other people's code you pulled in, checked against a CVE database. SAST scans *your own source code* for risky patterns the moment you write them. They are complementary: Trivy catches "you're using a library with a known hole", SAST catches "you just wrote a SQL query by string concatenation". A mature pipeline runs both.
::

---

## 2. Confirm Semgrep is installed

The base playground ships Semgrep pre-installed.

**Activity — Terminal (dev):** Check the version — the check records it to `/home/laborant/semgrep-version.txt`.

```bash
# Confirm Semgrep is on the PATH and record the version so the lab can confirm YOU ran this
semgrep --version | tee /home/laborant/semgrep-version.txt
```

::simple-task
---
:tasks: tasks
:name: verify_semgrep_installed
---
#active
In the **Terminal (dev)** tab, run `semgrep --version` and confirm it is installed — the check records it to `/home/laborant/semgrep-version.txt`.

#completed
Semgrep is installed and ready. ✓
::

---

## 3. Create a project to scan

The scanner needs code to analyze. We'll plant two classic flaws for it to find.

::hint-box
---
:summary: New to the terminal? Read this once (applies to every paste in this course).
---
Some activities paste a multi-line block into the terminal. **Copy the whole block at once** (from the first line through the final `EOF`) and press Enter — it runs as a single step. If your terminal ends up showing a lonely `>` on a new line, it's just waiting for the rest of an unfinished command: press **Ctrl + C** to cancel and paste the full block again. You can't break anything, and you can always re-run a step.
::

**Activity — Terminal (dev):** Create a small, deliberately flawed project.

```bash
mkdir -p /home/laborant/project/src

cat > /home/laborant/project/src/app.py << 'EOF'
import sqlite3

def get_user(username):
    conn = sqlite3.connect("app.db")
    # Vulnerability: SQL built by string concatenation
    query = "SELECT * FROM users WHERE name = '" + username + "'"
    return conn.execute(query).fetchall()

password = "hunter2"  # Vulnerability: hard-coded credential
EOF

cat /home/laborant/project/src/app.py
```

::simple-task
---
:tasks: tasks
:name: verify_project_created
---
#active
Create `/home/laborant/project/src/app.py` containing the two flawed patterns above.

#completed
The demo project is ready to scan. ✓
::

---

## 4. Run the scan and read the findings

**Activity — Terminal (dev):** Scan the project with Semgrep's auto config (it picks relevant community rules for the language).

```bash
# Scan the project — 'auto' selects relevant registry rules
semgrep scan --config auto /home/laborant/project
```

Semgrep prints each finding with the rule ID, the file and line, the matched code, and a short explanation of the risk. You should see the SQL-injection pattern and the hard-coded secret flagged.

::hint-box
---
:summary: What does --config auto actually do?
---
`--config auto` tells Semgrep to fetch a curated ruleset from the Semgrep Registry appropriate to the languages it detects in your project — including OWASP Top 10 and secret-detection rules. You can also pin specific rulesets (`--config p/python`, `--config p/owasp-top-ten`) for reproducibility, or write your own rule as a few lines of YAML. In CI you pin the ruleset so results don't drift between runs.
::

---

## 5. Save a machine-readable report

Humans read the console; pipelines read JSON. Save a JSON report a gate script can parse.

**Activity — Terminal (dev):** Write the report to a file.

```bash
# Produce a JSON report a pipeline can parse
semgrep scan --config auto --json -o /home/laborant/semgrep-report.json /home/laborant/project

# A gate: exit non-zero if any ERROR-severity finding exists
semgrep scan --config auto --error --severity ERROR /home/laborant/project \
  && echo "GATE PASSED" || echo "GATE FAILED (findings present)"
```

::hint-box
---
:summary: How does Semgrep become a merge gate?
---
The `--error` flag makes Semgrep return a non-zero exit code when it finds matching issues — exactly like Trivy's `--exit-code`. A CI job that runs this on every pull request fails the build when new ERROR-severity findings appear, blocking the merge. That is the Semgrep equivalent of a SonarQube quality gate: the policy ("no new ERROR findings") is enforced automatically, in seconds, right in the PR.
::

::simple-task
---
:tasks: tasks
:name: verify_scan_report
---
#active
Generate `/home/laborant/semgrep-report.json` with Semgrep's JSON output.

#completed
Machine-readable scan report saved. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **SAST** | Static Application Security Testing — analyze source without running it |
| **Semgrep** | Pattern-based SAST CLI; matches code structure, not text |
| **`--config auto`** | Fetch relevant community rules for the detected languages |
| **`--config p/owasp-top-ten`** | Pin a specific ruleset for reproducibility |
| **Severity** | ERROR / WARNING / INFO (Semgrep); Bug/Vuln/Smell/Hotspot (SonarQube) |
| **`--error`** | Return non-zero exit when findings exist (makes a gate) |
| **`--json -o`** | Write a machine-readable report |
| **Quality gate** | Automated pass/fail policy that can block a merge |
| **SonarQube** | Enterprise SAST platform (server-based) — the reference tool |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Análisis estático (SAST) con Semgrep**

- El **SAST** revisa tu código fuente sin ejecutarlo y marca bugs y patrones inseguros — un revisor que nunca se cansa.
- **Semgrep** es como un `grep` que entiende la *estructura* del código: detecta la *forma* peligrosa (SQL por concatenación, credencial embebida, llamada a shell con input) sin importar los nombres de variables.
- Clasifica por severidad **ERROR / WARNING / INFO**. Con `--error` devuelve un código de salida distinto de cero y se convierte en un **gate** que bloquea el merge — el equivalente al quality gate de SonarQube.
- Usamos Semgrep porque cabe en el microVM (un CLI, sin servidor). **SonarQube** es la herramienta de referencia empresarial, pero su servidor necesita ~2 GB de RAM solo para él, así que lo cubrimos en un recuadro. Lo aprendido aquí se transfiere directamente a SonarQube.
- Creaste un proyecto con dos fallos, lo escaneaste con `semgrep scan --config auto`, y guardaste un reporte JSON.
::

---

## Now Prove It

The challenge asks you to analyze a project, fail the gate on two real vulnerabilities, fix both, and re-scan until the gate passes clean.

::card
---
:challenge: challenges.semgrep-gate-04bd1d49
---
::
