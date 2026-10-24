---
kind: unit

title: Secret Scanning with Gitleaks

name: secret-scanning-gitleaks-unit-1
---

## Deleting a secret from a file doesn't delete it from history

Here is the mistake that has caused more breaches than almost anything else: a developer commits an API key, realizes the error, deletes it in the next commit, and moves on — believing it's gone. It is not. Git keeps **every version of every file forever**. That key is still sitting in the repository's history, one `git log -p` away, and if the repo is public, bots scraped it within minutes of the first push.

Leaked credentials are consistently among the top real-world breach causes. **Gitleaks** is the tool that finds them: it scans your working tree *and your entire Git history* for things that look like secrets — AWS keys, tokens, private keys, high-entropy strings — and reports exactly where each one lives.

::image-box
---
:src: __static__/gitleaks-history-v1.png
:alt: Diagram of a Git commit history as a horizontal chain of commits. An API key appears at commit 2, is "removed" at commit 4 (shown with a strikethrough in the working tree), but a magnifying glass labelled Gitleaks inspects the full chain and highlights that the secret still exists in the diff of commit 2, with a caption that deleting a file does not remove it from history
---
_Gitleaks scans the whole commit chain — a secret "deleted" in a later commit is still recoverable from the commit that introduced it._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tool:** Gitleaks (MIT) — `gitleaks`
- **Why it fits our microVM:** a single Go binary; scans a local repo and exits. No server.
- **Alternatives:** trufflehog (AGPL/… ) and `trivy fs --scanners secret` (Apache 2.0) also detect secrets — you already have Trivy.
- **Playground:** `devsecops-base`.
::

::hint-box
---
:summary: If a secret reached history, is scanning enough?
---
No — and this is critical. Once a secret is committed and pushed, you must **treat it as compromised and rotate it immediately**: revoke the key, issue a new one. Scrubbing it from history (with `git filter-repo` or BFG) is good hygiene but does not un-leak it — anyone could have copied it already. The order is always: **rotate first, then clean history.** Gitleaks tells you *what* to rotate; it cannot make an exposed secret safe again.
::

---

## 1. Create a repo with a leaked secret

**Activity — Terminal (dev):** Build a tiny repo, commit a fake AWS key, then "remove" it in a later commit — exactly the real-world mistake.

```bash
mkdir -p /home/laborant/leaky-repo && cd /home/laborant/leaky-repo
git init -q
git config user.email lab@example.com && git config user.name lab

# Commit 1: accidentally commit a secret
cat > config.py << 'EOF'
AWS_ACCESS_KEY_ID = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_ACCESS_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
EOF
git add config.py && git commit -qm "add config"

# Commit 2: "remove" it (but it's still in history!)
cat > config.py << 'EOF'
import os
AWS_ACCESS_KEY_ID = os.environ["AWS_ACCESS_KEY_ID"]
AWS_SECRET_ACCESS_KEY = os.environ["AWS_SECRET_ACCESS_KEY"]
EOF
git add config.py && git commit -qm "move creds to env"

echo "Working tree looks clean — but history is not:"
git log --oneline
```

::simple-task
---
:tasks: tasks
:name: verify_gitleaks
---
#active
Run `gitleaks version` to confirm the tool is installed.

#completed
Gitleaks is ready. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_repo
---
#active
Create the `/home/laborant/leaky-repo` Git repository with the two commits above.

#completed
The repo with a leaked secret is ready. ✓
::

---

## 2. Scan the history

**Activity — Terminal (dev):** Scan the full history and save a report. Even though the working tree is "clean", Gitleaks finds the secret in commit 1.

```bash
cd /home/laborant/leaky-repo

# detect scans the whole history by default
gitleaks detect -s /home/laborant/leaky-repo \
  -r /home/laborant/gitleaks-report.json -v

echo "Findings recorded in gitleaks-report.json"
```

::hint-box
---
:summary: detect vs protect — what's the difference?
---
`gitleaks detect` scans **committed history** — use it in CI and for auditing an existing repo. `gitleaks protect` scans **uncommitted/staged changes** — use it in a pre-commit hook to stop a secret *before* it ever becomes a commit. Detect is the safety net; protect is the gate. You want both.
::

::simple-task
---
:tasks: tasks
:name: verify_detect_report
---
#active
Scan the repo history and write findings to `/home/laborant/gitleaks-report.json`.

#completed
The leaked secret was found in history. ✓
::

---

## 3. Stop the next one with a pre-commit hook

Finding old leaks is reactive. The real win is *preventing* the next one. A Git pre-commit hook runs `gitleaks protect` on staged changes and blocks the commit if it finds a secret.

**Activity — Terminal (dev):** Install a pre-commit hook.

```bash
cat > /home/laborant/leaky-repo/.git/hooks/pre-commit << 'EOF'
#!/usr/bin/env bash
# Block the commit if Gitleaks finds a secret in staged changes
if ! gitleaks protect --staged -v; then
  echo "❌ Commit blocked: a secret was detected in staged changes."
  echo "   Remove it (and rotate it if it was ever real) before committing."
  exit 1
fi
EOF
chmod +x /home/laborant/leaky-repo/.git/hooks/pre-commit

echo "Pre-commit hook installed. Try staging a secret and committing — it will be blocked."
```

::hint-box
---
:summary: A hook lives on my machine — how do I enforce this for the whole team?
---
Local hooks are opt-in and easy to skip (`git commit --no-verify`), so they're a developer convenience, not a guarantee. The enforcement layer is **CI**: run `gitleaks detect` as a required pipeline step on every push and pull request, so a secret that slips past a local hook still fails the build before merge. Belt and suspenders — the hook catches most, CI catches the rest. Tools like `pre-commit` (the framework) can also distribute hooks across a team.
::

::simple-task
---
:tasks: tasks
:name: verify_precommit_hook
---
#active
Install a `.git/hooks/pre-commit` that runs `gitleaks protect --staged`.

#completed
Your pre-commit secret gate is installed. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **Secret leak** | Credential committed to a repo — a top breach vector |
| **Git history** | Keeps every version; "deleting" a secret doesn't remove it |
| **Gitleaks** | Scans working tree and history for secrets |
| **`gitleaks detect`** | Scan committed history (CI, audits) |
| **`gitleaks protect --staged`** | Scan staged changes (pre-commit gate) |
| **Rotate first** | An exposed secret must be revoked/reissued, not just scrubbed |
| **Pre-commit hook** | Local gate; `--no-verify` can bypass it |
| **CI enforcement** | The real guarantee — required scan on every push/PR |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Escaneo de secretos con Gitleaks**

- Borrar un secreto de un archivo **no lo borra del historial**. Git guarda todas las versiones para siempre; una clave "eliminada" sigue en el commit que la introdujo — y si el repo es público, los bots ya la copiaron.
- Las credenciales filtradas son de las principales causas de brechas reales. **Gitleaks** escanea el árbol de trabajo y **todo el historial** buscando claves, tokens y cadenas de alta entropía.
- `gitleaks detect` escanea el historial (CI, auditorías); `gitleaks protect --staged` escanea cambios en staging (hook pre-commit). Usa ambos.
- **Regla clave:** si un secreto llegó al historial, **rótalo de inmediato** (revoca y reemplaza) — limpiar el historial no deshace la filtración.
- Creaste un repo con una clave filtrada, la encontraste con `gitleaks detect`, e instalaste un hook pre-commit que bloquea el próximo secreto.
::

---

## Now Prove It

The challenge gives you a repo with a secret hidden in history and asks you to detect it, install a working pre-commit gate, and document the rotation step.

::card
---
:challenge: challenges.gitleaks-scan-6d67fce8
---
::
