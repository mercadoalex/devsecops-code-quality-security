---
kind: unit

title: Technical Debt & "Clean as You Code"

name: technical-debt-clean-as-you-code-unit-1
---

## You can't pay down a debt you never measured

Every shortcut you take to ship faster is a small loan against future effort. Taken individually, each is reasonable. Taken together, they become **technical debt** — the accumulated cost of all the corners you cut. Left unmeasured, it compounds silently until a "quick change" takes two weeks and nobody knows why.

The trap most teams fall into is "we'll fix all of it someday". You almost never can — a large legacy base has thousands of issues and the cleanup project gets cancelled halfway. The strategy that actually works is **clean as you code**: require that *new and changed* code meets your standard, and leave old code alone until you touch it.

::image-box
---
:src: __static__/tech-debt-clean-as-you-code-v1.png
:alt: Two line charts side by side over time. The left chart "Fix everything" shows total debt as a flat high line that barely moves because the team never catches up. The right chart "Clean as you code" shows overall debt slowly declining while a highlighted band for new code stays at zero, illustrating that gating only new code steadily improves the whole base
---
_"Clean as you code": gate only the new code. Old debt stays visible but you never add more, and the overall line trends down over time._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tool:** Semgrep OSS with `--baseline-commit` (baseline/diff scanning)
- **License:** LGPL 2.1 + permissive rules — free, no server
- **Why it fits our microVM:** baseline scanning is just two CLI runs compared in memory; no server or database needed.
- **Enterprise reference it stands in for:** SonarQube's Maintainability (SQALE) rating and its "new code" quality gate — same concept, platform-scale.
::

::hint-box
---
:summary: Why not just fix all the existing debt first?
---
Because you almost never can. A "stop everything and fix it all" project competes with feature work and usually loses. **Clean as you code** flips the strategy: require that *new and changed* code meets your standard, and leave the old code alone until you modify it. New problems stop appearing immediately, and the base improves wherever active work happens. It is the single most practical idea in this lesson.
::

---

## 1. How debt gets rated

Platforms like SonarQube express maintainability as a letter rating (the **SQALE rating**, A–E) based on the ratio of estimated remediation time to development time:

| Rating | Debt ratio | Reading |
|---|---|---|
| A | ≤ 5% | Healthy |
| B | 6–10% | Minor cleanup needed |
| C | 11–20% | Noticeable drag |
| D | 21–50% | Serious |
| E | > 50% | Fixing costs more than a rewrite of this slice |

You don't need a server to act on the same idea. With Semgrep you count findings, track them over time, and — crucially — separate *existing* findings from *new* ones with a **baseline**.

---

## 2. Establish a baseline of existing debt

A baseline is a snapshot of the findings that already exist. Once you have it, the gate can ignore the old findings and fail only on *new* ones — the mechanism behind clean-as-you-code.

**Activity — Terminal (dev):** Confirm Semgrep, then capture a baseline of the demo project's current findings.

```bash
# Record the version so the lab can confirm YOU ran this step
semgrep --version | tee /home/laborant/semgrep-version.txt

cd /home/laborant/project
# Snapshot the current findings as the "accepted legacy debt" baseline
semgrep scan --config auto --json -o /home/laborant/project/.semgrep-baseline.json .
echo "Baseline captured: $(jq '.results | length' /home/laborant/project/.semgrep-baseline.json) existing findings"
```

::hint-box
---
:summary: In a real repo, how does the baseline work with Git?
---
Semgrep can diff against a Git commit: `semgrep scan --baseline-commit <sha>` reports only findings introduced *after* that commit. In CI you set the baseline to the target branch (e.g. `main`), so the scan fails the pull request only on findings the PR *adds*. The JSON snapshot we take here is the no-Git equivalent — a recorded set of "already accepted" findings to compare against.
::

::simple-task
---
:tasks: tasks
:name: verify_semgrep
---
#active
Run `semgrep --version` to confirm the tool is available — the check records it to `/home/laborant/semgrep-version.txt`.

#completed
Semgrep is ready. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_baseline
---
#active
Capture `/home/laborant/project/.semgrep-baseline.json` as your legacy-debt baseline.

#completed
Baseline of existing debt captured. ✓
::

---

## 3. Define your gate policy on new code

Write down the policy your pipeline enforces. The key rule: strictness applies to **new** code.

**Activity — Terminal (dev):** Describe the gate as a JSON file. It must target new code.

```bash
cat > /home/laborant/quality-gate.json << 'EOF'
{
  "name": "DevSecOps clean-as-you-code gate",
  "applies_to": "new_and_changed_code",
  "baseline": ".semgrep-baseline.json",
  "conditions": [
    { "rule": "no new ERROR-severity findings", "action": "fail" },
    { "rule": "no new hard-coded secrets", "action": "fail" },
    { "rule": "new code security rating must be A", "action": "fail" },
    { "rule": "existing (baseline) findings", "action": "report_only" }
  ]
}
EOF

cat /home/laborant/quality-gate.json
```

::simple-task
---
:tasks: tasks
:name: verify_gate_definition
---
#active
Create `/home/laborant/quality-gate.json` describing a gate that targets **new** code against the baseline.

#completed
Your clean-as-you-code gate is defined. ✓
::

---

## 4. Write a debt paydown plan

Measuring debt is step one; a plan to manage it is step two.

**Activity — Terminal (dev):** Write a short plan that commits to clean-as-you-code and says how legacy debt is handled.

```bash
cat > /home/laborant/debt-plan.md << 'EOF'
# Technical debt plan

## Strategy: clean as you code
- The gate enforces standards on NEW code only (diffed against the baseline).
- We never merge new code that adds an ERROR finding or a hard-coded secret.
- Existing (legacy) debt is tracked but not blocking; we fix it opportunistically
  whenever we modify the surrounding code.

## Cadence
- Review the top 5 highest-effort findings each sprint.
- Budget 10% of each sprint to paying down legacy debt in actively changed areas.
- Re-baseline after a deliberate cleanup so the number only moves down.
EOF

cat /home/laborant/debt-plan.md
```

::simple-task
---
:tasks: tasks
:name: verify_debt_notes
---
#active
Create `/home/laborant/debt-plan.md` describing a clean-as-you-code strategy and how legacy debt is handled.

#completed
Your debt paydown plan is written. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **Technical debt** | Accumulated cost of shortcuts; estimated remediation time |
| **SQALE / Maintainability Rating** | A–E rating of debt ratio (SonarQube) |
| **Baseline** | Snapshot of accepted existing findings |
| **`--baseline-commit <sha>`** | Semgrep reports only findings added after a commit |
| **Clean as you code** | Gate new code strictly; fix legacy opportunistically |
| **Report-only** | Surface legacy findings without blocking |
| **Re-baseline** | Update the snapshot after a deliberate cleanup |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Deuda técnica y "clean as you code"**

- Cada atajo para entregar rápido es un préstamo contra el esfuerzo futuro. En conjunto forman la **deuda técnica**, que se acumula en silencio si no se mide.
- El error común es "lo arreglaremos todo algún día" — casi nunca ocurre. La estrategia que funciona es **clean as you code**: exigir que el código **nuevo** cumpla el estándar y dejar el legado hasta que lo toques.
- SonarQube lo mide con el **rating SQALE (A–E)**. Sin servidor, logras lo mismo con un **baseline** de Semgrep: una foto de los hallazgos existentes para que el gate falle solo con los **nuevos** (`--baseline-commit` en CI).
- Capturaste un baseline, definiste un gate enfocado en código nuevo, y escribiste un plan de pago de deuda.
::

---

## Now Prove It

The challenge asks you to establish a baseline, define a clean-as-you-code gate, and write a debt-management plan a reviewer could actually follow.

::card
---
:challenge: challenges.tech-debt-562e044d
---
::
