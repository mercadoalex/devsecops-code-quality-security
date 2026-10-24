---
inclusion: manual
---

# iximiuz Labs — Task Reference

---

## Three task types

| Type | Blocks playground start? | Visible to student? | Use for |
|------|--------------------------|---------------------|---------|
| `init` | **Yes** — spinner until all pass | No | Environment setup before student sees anything |
| `helper` | No | No | Background setup running throughout session |
| `regular` | No | Yes (pass/fail boxes) | Verifying student actions |

---

## Confirmed-working schema (copy this exactly)

Regular tasks — the only type with student-visible UI:

```yaml
tasks:
  verify_something:
    machine: <machine-name>   # must match playground.yaml machine name exactly
    user: laborant
    run: |
      # exit 0 = pass (green), exit 1 = fail (retried)
      kubectl get clusterqueue gpu-quota -o jsonpath='{.status.conditions[0].type}' \
        | grep -q "Active" || exit 1
      echo "ClusterQueue is Active ✓"

  verify_lesson_complete:
    machine: <machine-name>
    user: laborant
    needs:
      - verify_something
    run: |
      echo "Lesson complete ✓"
```

**Fields used: `machine`, `user`, `run`, `needs`. Nothing else.**

Do NOT add: `timeout_seconds`, `init: true` on regular tasks, or any other
undocumented field. These cause the "Warming up playground" hang or silent failures.

---

## machine property — all or nothing

> If **any** task has `machine:`, then **every** task must have `machine:`.
> You cannot mix tasks with and without it.

---

## `::simple-task` markdown component

Every regular task **must** have a corresponding `::simple-task` in `unit-1.md`.
Tasks without a visual representation are invisible to students.

```markdown
::simple-task
---
:tasks: tasks
:name: verify_something         ← must exactly match the task key in index.md
---
#active
What the student needs to do. Be specific — name the file, URL, or command.

#completed
Confirmation message ✓
::
```

**Rules:**
- `:tasks: tasks` — always literally `tasks`, never the task name
- `:name:` — exact match to the key in the `tasks:` block
- Do NOT write "Hit Check" or "press Check" in `#active` — tasks run automatically
- The final task in every lesson is always `verify_lesson_complete`:

```markdown
::simple-task
---
:tasks: tasks
:name: verify_lesson_complete
---
#active
All N tasks are green — this lesson is complete.

#completed
Lesson complete. On to the next one! ✓
::
```

---

## User-input task

Used when the student needs to submit a value (e.g. reading a token or pod name):

```markdown
::user-input-task
---
:tasks: tasks
:name: input_value
:validateRegex: ^[0-9a-zA-Z-]{2,64}$    ← client-side validation before submission
:destination: /tmp/student-input.txt     ← written to this path in the VM
---
#active
Enter the value shown in your terminal output:

#completed
Got it ✓
::
```

Corresponding frontmatter task receives it via `x(.input)`:

```yaml
tasks:
  input_value:
    machine: <machine-name>
    run: |
      # User's input is available as the literal string x(.input)
      # Or read from :destination: path if set
      cat /tmp/student-input.txt
```

---

## `needs:` and task output chaining

```yaml
tasks:
  input_pod_name:
    machine: <machine-name>
    run: |
      echo "ok"

  verify_pod_running:
    machine: <machine-name>
    needs:
      - input_pod_name
    env:
      - POD_NAME=x(.needs.input_pod_name.input)
    run: |
      kubectl get pod "${POD_NAME}" -o jsonpath='{.status.phase}' \
        | grep -q "Running" || exit 1
```

Template variables from `needs`:
- `x(.needs.<task>.stdout)` — trimmed stdout
- `x(.needs.<task>.input)` — user input (user-input-task only)
- `x(.needs.<task>.exit_code)` — exit code

---

## `hintcheck` and `failcheck`

```yaml
tasks:
  verify_something:
    machine: <machine-name>
    run: |
      kubectl get pod my-pod | grep -q Running || exit 1
    hintcheck: |
      # stdout shown to student as a hint — exit code has NO effect on task outcome
      kubectl get pod my-pod
    failcheck: |
      # If this exits non-zero → task FAILED → ENTIRE PLAYGROUND FAILED → student must restart
      # Use only for unrecoverable states
      kubectl get pod my-pod 2>/dev/null || {
        echo "Pod was deleted — please restart the playground."
        exit 1
      }
```

| Script | When it runs | Exit code effect | Shown to student |
|--------|-------------|------------------|------------------|
| `run` | Main loop | non-zero = retry | No |
| `hintcheck` | After `run` | Ignored | Yes — as hint |
| `failcheck` | Before `run` | non-zero = playground failed | Yes — as error |

Use `failcheck` sparingly. A failed playground requires a full restart.

---

## Play variables (`vars`)

Feed values from tasks back into the lesson content:

```yaml
vars:
  NODE_IP:
    shell: kubectl get node -o jsonpath='{.items[0].status.addresses[0].address}'
    machine: <machine-name>
  VLLM_URL: http://x(.vars.NODE_IP):8000/
```

Use in markdown:
```markdown
Your vLLM endpoint: {{ vars.VLLM_URL || 'resolving...' }}

Copy-ready: :code-var{name=VLLM_URL default='http://...'}
```

**Restrictions:**
- Bindings do NOT expand inside inline code or fenced code blocks
- Bindings inside table cells fail markdown validation — use a list instead

---

## Execution flow

```
Playground starts
  └── All init tasks run in parallel
        └── All exit 0 → spinner clears → regular tasks begin looping
        └── Any exit non-zero → spinner never clears (playground stuck)

Regular tasks run in parallel by default
  └── needs: creates a sequential dependency
  └── Each task loops until exit 0 → turns green
```

---

## Debugging

Task output is hidden from students. Access it as the content author:
- `examinerctl` CLI on the playground machine, or
- **Tasks Dev Tools** button (bottom-right of playground — author-only, invisible to students)
