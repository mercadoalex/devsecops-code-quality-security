---
inclusion: manual
---

# iximiuz Labs — Challenge Authoring Rules

Lessons learned the hard way. Follow these rules exactly or the challenge will
show "Couldn't load the challenge" on the platform.

---

## Three independent files across two directories

```
challenges/
  <name>/
    index.md                    ← kind: challenge  (standalone, independent of any lesson)

course-N/
  module-X/
    Y.lesson-name/
      index.md                  ← kind: lesson     (references the challenge slug)
      unit-1.md                 ← kind: unit       (embeds the ::card at the bottom)
```

The `challenges/` directory is completely independent from `course-N/`.
The challenge exists on its own — it is linked into a lesson by slug reference,
not by file proximity.

---

## 1. Lesson `index.md` — how to reference a challenge

```yaml
---
kind: lesson
title: Your Lesson Title
name: your-lesson-name
slug: your-lesson-name
createdAt: 2026-09-03
updatedAt: 2026-09-03
categories:
  - kubernetes        # from the closed list
tagz:
  - kueue
  - gpu-scheduling
playground:
  name: <playground-slug>   # must match labctl playground list exactly
challenges:
  <platform-slug>: {}       # BEFORE tasks:
tasks:
  verify_something:
    machine: <machine-name>
    user: laborant
    run: |
      ...
  verify_lesson_complete:
    machine: <machine-name>
    user: laborant
    needs:
      - verify_something
    run: |
      echo "Lesson complete ✓"
---
```

**Rules:**
- `challenges:` comes **before** `tasks:` — order matters
- Challenge slug value is always `{}` — no extra config
- Slug must exactly match what `labctl content create` printed
- Nothing after the closing `---` — no body content in `index.md`

---

## 2. Lesson `unit-1.md` — structure and challenge card

### Frontmatter

```yaml
---
kind: unit
title: Your Lesson Title
name: your-lesson-name-unit-1
---
```

Three fields only. No `tagz`, no `playground`, no `tasks`.

### Challenge card — always the last thing in the file

```markdown
---

## Now Prove It

::card
---
:challenge: challenges.<platform-slug>
---
::
```

The slug in `::card` must exactly match the slug in `challenges:` in `index.md`
and what the platform assigned at `labctl content create` time.

---

## 3. Challenge `index.md` — the standalone challenge file

Lives in `challenges/<name>/index.md`. Two key rules:
- **No `name:` or `slug:` fields** — platform assigns the slug at creation; these cause HTTP 400
- **Every task in frontmatter MUST have a matching `::simple-task` in the body**

```yaml
---
kind: challenge
title: 'Your Challenge Title'
description: |
  One paragraph description shown in the challenge card.
categories:
  - kubernetes
tagz:
  - kueue
difficulty: easy    # easy | medium | hard
createdAt: 2026-09-03
updatedAt: 2026-09-03
playground:
  name: <playground-slug>
tasks:
  task_name_1:
    machine: <machine-name>
    user: laborant
    run: |
      echo "ok"
  task_name_2:
    machine: <machine-name>
    user: laborant
    needs:
      - task_name_1
    run: |
      echo "ok"
---

## Challenge title

Instructions for the student.

::simple-task
---
:tasks: tasks
:name: task_name_1
---
#active
Waiting for task_name_1 to pass...

#completed
Task 1 complete. ✓
::

::simple-task
---
:tasks: tasks
:name: task_name_2
---
#active
Waiting for task_name_2 to pass...

#completed
Task 2 complete. ✓
::
```

---

## 4. Full workflow — creating a new challenge

```bash
# Step 1 — create on platform (first time only) — SAVE THE SLUG IT PRINTS
labctl content create challenge <local-name> -d challenges/<local-name> --no-open -q

# Step 2 — push the challenge content
labctl content push -f challenge <platform-slug> -d challenges/<local-name>

# Step 3 — update lesson index.md with the slug under challenges:
# Step 4 — update lesson unit-1.md with ::card block at the end
# Step 5 — push the whole course (BOTH challenge AND course must be pushed)
labctl content push -f course <course-slug> -d course-N
```

**Always use `-f` (force) flag** — without it `labctl` prompts interactively
and silently skips all files when no TTY is available.

---

## 5. Common errors

| Error | Cause | Fix |
|---|---|---|
| "Couldn't load the challenge" | No `::simple-task` blocks in challenge body | Add one per task in frontmatter |
| "Couldn't load the challenge" | Wrong slug in `::card` or `challenges:` | Check with `labctl content list` |
| Challenge not visible in lesson | Course not pushed after `index.md` change | `labctl content push -f course ...` |
| `labctl: not found` | Pushing before creating | Run `labctl content create` first |
| Tasks don't run | `needs:` chain broken | Verify task names match exactly in frontmatter and `::simple-task` |
| All files silently skipped | No `-f` flag, interactive prompt with no TTY | Always use `-f` |

---

## 6. Checking slugs

```bash
# List all published content
labctl content list

# Pull what the platform has (works for drafts too)
labctl content pull challenge <slug> -d /tmp/check-pull
```

`labctl content list` only shows **published** content. Drafts can be pulled
by slug but won't appear in the list.
