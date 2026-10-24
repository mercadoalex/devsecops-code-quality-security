---
inclusion: manual
---

# iximiuz Lesson Authoring Pattern

The canonical pattern for writing `unit-1.md` content. Every lesson follows
this structure: a catchy hook, progressive concept sections, activities at every
step, and hint boxes so nobody feels lost.

---

## File structure — three files per lesson

```
course-N/
  module-X/
    Y.lesson-name/
      index.md       ← kind: lesson  — frontmatter only (metadata, tasks, challenge refs)
      unit-1.md      ← kind: unit    — ALL readable content lives here
      __static__/    ← images for this lesson (PNG, named with -vN suffix)
        .gitkeep
```

`index.md` and `unit-1.md` are strictly separated:
- No content body in `index.md`
- No task definitions in `unit-1.md`

---

## Anatomy of `unit-1.md`

### 1. Frontmatter

```yaml
---
kind: unit
title: Your Lesson Title
name: your-lesson-slug-unit-1
---
```

Three fields only. `kind: unit` is required exactly as written.

---

### 2. Opening hook

The first section answers "why should I care?" before any code appears.
**Do not name it "Introduction"** — use a punchy headline.

```markdown
## [Surprising fact, bold claim, or "you already X" framing]

[1–3 short paragraphs connecting the student's existing knowledge to the new topic.
Use "you". Tell a tiny story or reveal something unexpected.]

::image-box
---
:src: __static__/concept-overview-v1.png
:alt: [Full description of every element in the diagram for screen readers]
:max-width: 860px
---
_Caption explaining what the diagram shows and why it matters._
::

::hint-box
---
:summary: [The doubt the nervous student has right now]
---
[Answer it directly before any code appears.]
::
```

Good hook patterns:
- Reveals a surprising truth: *"Every kubectl apply you've run queues a job — you just couldn't see the queue."*
- Connects to prior course: *"In Module 3 you configured a ClusterQueue. This lesson shows what happens inside Kueue when that queue fills up."*
- Removes anxiety before it starts: *"Do I need to understand MIG internals to complete this? No."*

---

### 3. Content sections

Numbered `## 1.`, `## 2.`, etc. Target 4–6 sections per lesson.
Each section follows this internal structure:

```
[Concept explanation — 1–3 paragraphs or a table]
[Code block — annotated with comments]
[::hint-box — explains the non-obvious thing in the code]
[Activity — paste-ready terminal command or manifest to apply]
[::simple-task — verification for the activity]
```

Not every section needs a `::simple-task` — only sections where the student
produces something verifiable. Target 3–5 tasks per lesson.

---

### 4. Image boxes

> **Images carry the concepts. People scan images before they read prose.**
> Treat diagrams as a primary teaching tool, not decoration. A lesson that
> explains a concept in words alone is an unfinished lesson.

**Image-density target: one `::image-box` per major concept section, minimum.**
A typical lesson has 4–6 content sections → aim for **4–6 diagrams per lesson**,
plus the opening hook image. Any time you introduce:
- an architecture or data flow → draw it
- a before/after state change → show both states side by side
- a comparison (A vs B) → two-panel diagram
- a sequence of steps → numbered flow diagram
- a resource model or hierarchy → boxes-and-arrows diagram

If you're writing more than ~3 paragraphs with no image, stop and add one.

```markdown
::image-box
---
:src: __static__/filename-v1.png
:alt: [Detailed: panels, labels, arrows, colours, annotations]
:max-width: 860px
---
_Caption: what the diagram shows + why it matters in one sentence._
::
```

**Naming:** `<concept>-<descriptor>-v<N>.png` — use `v1`, `v2` when replacing;
never overwrite. Images appear **before** the code block they illustrate.

**Every image needs a `.todo` spec file** when the PNG doesn't exist yet. The
`.todo` file (named `<image>.png.todo`) must contain: purpose, composition
breakdown, and a ready-to-paste Gemini prompt that ends with the base style
fragment from `visual-style.md`. This lets images be generated in a batch later
without re-deriving what each one should show. See `visual-style.md` for the
color system and prompt structure — all images across all courses must match it.

When an image doesn't exist yet, create a `.todo` placeholder:
```
__static__/concept-diagram-v1.png.todo   ← describe exactly what the image should show
```

---

### 5. Hint boxes

The primary tool for making students feel safe. Use heavily.

```markdown
::hint-box
---
:summary: [The question in the student's head right now]
---
[Answer completely. Can include code blocks, tables, lists.]
::
```

**When to add one:**
- After new syntax — "Why does X work like this?"
- Before an activity — "What if I already have Y from the previous step?"
- After non-obvious code — "Why do we need Z here?"
- Any common beginner mistake — name it and defuse it
- Production gotchas that don't belong in the main flow

**Target density:** 8–12 per lesson. One per major code block minimum.

**Good summary labels:**
- `Why does Kueue need a LocalQueue AND a ClusterQueue?`
- `Do I need to understand MIG internals for this task?`
- `What's the difference between preemption and borrowing?`
- `Coming from Module 3? Here's where we left off.`

**Bad labels:** `More info`, `Details`, `Note`, `Tip` — too vague.

---

### 6. Activities

Every section that produces a verifiable artefact ends with an Activity.

```markdown
**Activity — Terminal:** Apply the ClusterQueue manifest and verify it becomes Active.

```bash
# Apply the manifest
kubectl apply -f course-1/manifests/clusterqueue-default.yaml

# Verify — should show Active
kubectl get clusterqueue gpu-quota -o jsonpath='{.status.conditions[0].type}'
```
```

**Rules:**
- Always name the terminal tab: `Terminal`, `Terminal (node-1)`, etc.
- Paste-ready commands only — no `<placeholder>` values
- Add `# comments` on lines that need explanation
- For multi-step activities, add a numbered purpose list before the commands

#### Writing K8s manifests from bash activities

Use `tee` with a quoted heredoc:

```bash
tee /tmp/clusterqueue.yaml << 'EOF'
apiVersion: kueue.x-k8s.io/v1beta1
kind: ClusterQueue
metadata:
  name: gpu-quota
spec:
  namespaceSelector: {}
  resourceGroups:
    - coveredResources: ["nvidia.com/gpu"]
      flavors:
        - name: default-flavor
          resources:
            - name: "nvidia.com/gpu"
              nominalQuota: 4
EOF
kubectl apply -f /tmp/clusterqueue.yaml
```

**Rule:** every YAML key-value in the heredoc must fit on a single line. Multi-line
values cause parse errors because the shell writes newlines literally.

#### curl → parsing output (critical gotcha)

**Never pipe curl directly to python3** — curl closes the pipe before python3
finishes reading stdin, producing empty output and a `JSONDecodeError`.

```bash
# WRONG
curl -s http://localhost:8000/v1/models | python3 -c "import sys,json; ..."

# CORRECT — always capture first, then parse
RESPONSE=$(curl -s http://localhost:8000/v1/models)
echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['id'])"
```

Apply this pattern to every `curl → python3` command in all lessons.

---

### 7. Simple-task blocks

```markdown
::simple-task
---
:tasks: tasks
:name: verify_clusterqueue_active
---
#active
In the **Terminal**, run `kubectl get clusterqueue gpu-quota` and confirm
the STATUS shows `Active`.

#completed
ClusterQueue gpu-quota is Active ✓
::
```

**Active text:** specific — name the exact command, file, or output to look for.
**Completed text:** short, positive, closes the loop.

The final task in every lesson:

```markdown
::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
All N tasks are green — this lesson is complete.

#completed
[Module topic] lesson complete. On to the next one! ✓
::
```

---

### 8. Key concepts reference table

Every lesson ends with a cheat-sheet table before the challenge card:

```markdown
## Key concepts reference

| Concept | Detail |
|---------|--------|
| ClusterQueue | Cluster-scoped quota pool — defines total GPU budget |
| LocalQueue | Namespace-scoped — teams submit jobs here |
| Cohort | Group of ClusterQueues that can borrow from each other |
```

---

### 9. Challenge card — last element

```markdown
---

## Now Prove It

::card
---
:challenge: challenges.<platform-slug>
---
::
```

See `iximiuz-challenge-authoring.md` for slug workflow.

---

## Section checklist

- [ ] Opening section has a punchy headline (not "Introduction")
- [ ] First hint box reassures before any code appears
- [ ] At least one `::image-box` in the intro and each major section
- [ ] Every `::image-box` has detailed `:alt:` and a caption
- [ ] Every non-obvious code pattern has a `::hint-box` immediately after
- [ ] Every activity names the terminal tab
- [ ] All commands are paste-ready (no placeholders)
- [ ] Every activity followed by a `::simple-task`
- [ ] Task names in `::simple-task` match task names in `index.md` exactly
- [ ] `verify_lesson_complete` is the last task
- [ ] `## Key concepts reference` table present before challenge card
- [ ] `## Now Prove It` + `::card` is the absolute last element
- [ ] `curl | python3` uses the capture-then-pipe pattern (never direct pipe)

---

## Tone rules

| Do | Don't |
|----|-------|
| Use "you" throughout | Use "the student" or passive voice |
| Short sentences — one idea each | Run-on explanations |
| Name the surprising thing first, then explain | Explain first, reveal second |
| Acknowledge what's confusing before explaining it | Assume it's obvious |
| Bold key terms on first use | Introduce terms without emphasis |
| `> ⚠️ Reference only — do not paste this` for non-runnable blocks | Show non-runnable code without a warning |
| `> ⏱️ This can take 60–120 seconds` for slow operations | Leave the student wondering if it's stuck |
