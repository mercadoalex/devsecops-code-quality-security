---
inclusion: manual
---

# iximiuz Labs — Frontmatter Reference & Gotchas

---

## Field name traps (things that silently break)

| Wrong | Right | Effect of using wrong |
|-------|-------|----------------------|
| `tags:` | `tagz:` | Tags silently ignored — no error |
| category word in `tagz:` (e.g. `kubernetes`, `observability`) | put it in `categories:` only | HTTP 400 — "tags must not include known categories" |
| `SYLLABUS.md` / stray `.md` in the pushed dir | keep planning docs OUTSIDE the `-d` dir | HTTP 400 — "Content kind course does not support files with kind undefined" |
| `"2026-09-03"` (quoted) | `2026-09-03` (bare date) | Tasks block **silently ignored entirely** — content appears but no tasks run |
| `name:` in challenge | _(omit it)_ | HTTP 400 — platform assigns slug at creation |
| `slug:` in challenge | _(omit it)_ | HTTP 400 — same reason |
| body content in lesson `index.md` | Put it in `unit-1.md` | Content not rendered — lesson appears blank |

**Course vs lesson index.md body — opposite rules:**
- **Lesson `index.md`** — NO body after the closing `---`. Content lives in `unit-1.md`.
- **Course `index.md`** — the body AFTER the frontmatter IS the "About this course" page (## What you'll learn, ## Prerequisites, ## Lab environment, etc.). A course with no body shows a blank About section.
- **Module `0.index.md`** — frontmatter only, no body.

**The `createdAt` / `updatedAt` trap is the most dangerous** — the platform YAML parser
silently drops the entire `tasks:` block when dates are quoted strings. Always bare dates.

---

## Lesson structure (`kind: lesson`)

```yaml
---
kind: lesson

title: <string>
description: |
  Optional description.

name: <string>        # unique identifier — kebab-case
slug: <string>        # same as name

createdAt: 2026-09-03     # bare date — NOT "2026-09-03"
updatedAt: 2026-09-03

categories:           # 1-2 from the closed list below
  - kubernetes

tagz:                 # up to 5 tags (note: tagz with a z)
  - kueue
  - gpu-scheduling

playground:
  name: <playground-slug>   # exact match from labctl playground list

challenges:           # optional — MUST come before tasks:
  <platform-slug>: {}

tasks:
  verify_something:
    machine: <machine-name>
    user: laborant
    run: |
      ...
---
```

Nothing after the closing `---`. All readable content goes in `unit-1.md`.

---

## Unit structure (`kind: unit`)

```yaml
---
kind: unit

title: <string>

name: <lesson-slug>-unit-1    # convention: append -unit-1
---
```

Three fields only. Everything else (tasks, playground, challenges) lives in `index.md`.

---

## Module structure (`kind: module`)

```yaml
---
kind: module

title: <string>
name: module-N         # REQUIRED — without this, modules show as {} and lessons show "not found"
description: |
  ...

createdAt: 2026-09-03
updatedAt: 2026-09-03
---
```

`name:` on module files is not optional. Missing it causes the entire module to
be invisible in the course even after a successful push.

---

## Challenge structure (`kind: challenge`)

```yaml
---
kind: challenge

title: '<string>'
description: |
  One paragraph.

categories:
  - kubernetes

tagz:
  - kueue

difficulty: easy      # easy | medium | hard

createdAt: 2026-09-03
updatedAt: 2026-09-03

playground:
  name: <playground-slug>

tasks:
  task_name:           # lowercase, underscores only — no hyphens in task names
    machine: <machine-name>
    user: laborant
    run: |
      echo "ok"
---
```

No `name:` or `slug:` — platform assigns the slug at `labctl content create` time.

---

## Valid categories (closed list)

```
linux
networking
containers
kubernetes
programming
observability
security
ci-cd
```

Using a category not in this list causes a validation error at push time.

---

## Playground frontmatter

When defining machines inline in content (rather than referencing a registered playground):

```yaml
playground:
  machines:
    - name: dev-machine
      drives:
        - mount: /
          source: oci://ghcr.io/<org>/<image>:<tag>    # oci:// prefix required
      users:
        - name: laborant
          default: true
      network:
        interfaces:
          - network: local    # network must be an object, not a string
  tabs:
    - id: terminal-dev       # all tab IDs must be unique within the playground
      kind: terminal
      machine: dev-machine
      name: Terminal
    - id: http-port-9090     # unique ID per tab
      kind: http-port
      name: Prometheus
      machine: dev-machine
      number: 9090
```

**Playground gotchas from production:**
- `oci://` scheme prefix is required on drive `source` — bare registry paths cause HTTP 400
- `mount: /` is required on drives — missing it causes "no root drive found" error
- Tab IDs must all be unique — duplicate IDs cause "Tab IDs must be unique" HTTP 400
- `network:` must be an object with `interfaces:` — not a plain string like `network: default`
- Valid `accessControl` principals: `owner`, `anyone`, `authenticated`,
  `github:<handle>`, `student:<training-name>` — strings like `role:registered` are invalid

---

## Fetch existing tags

```bash
curl https://labs.iximiuz.com/api/content/tags?kind=tutorial
curl https://labs.iximiuz.com/api/content/tags?kind=challenge
curl https://labs.iximiuz.com/api/content/tags?kind=course
```
