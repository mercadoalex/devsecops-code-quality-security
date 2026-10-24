# iximiuz Labs — Background Tasks (Task Execution Engine)

Source: https://github.com/iximiuz/labs/blob/main/content-samples/sample-tutorial/index.md
Also: iximiuz Labs content authoring documentation

---

## Overview

Each machine in the playground can run three types of tasks:

| Type | Blocks playground start? | UI representation | Use for |
|---|---|---|---|
| `init` | **Yes** — playground shows loading screen until all init tasks complete | None (loading screen only) | Environment setup before student sees anything |
| `helper` | **No** — playground starts immediately | None | Background setup that can run during the whole playground lifetime |
| `regular` | No | Visible task boxes with pass/fail state | Verifying student actions, providing feedback |

---

## Task Types

### `init` — Initialization Task

Runs during playground initialization before the UI is fully available. **All init tasks must complete before the playground loading screen clears.**

```yaml
tasks:
  init_deploy_nginx:
    init: true          # marks this as an init task

    machine: dev-machine  # optional — if omitted, runs on every machine.
                          # IMPORTANT: either none or ALL tasks must have
                          # the machine property. You cannot mix.

    user: laborant      # optional — defaults to root if omitted

    run: |
      kubectl run nginx-01 --image=ghcr.io/iximiuz/labs/nginx:alpine --port=80
```

**Key rules:**
- Until all `init` tasks exit 0, the playground shows a loading animation
- If an `init` task times out or exits non-zero, the loading screen **never clears** — the playground hangs forever
- No `timeout_seconds` field is documented — do not invent one
- `init` tasks have no UI representation — students never see them

### `helper` — Helper Task

Similar to `init` but does **not** block playground startup. Can run at any point during the playground's lifetime.

```yaml
tasks:
  helper_setup_something:
    helper: true
    machine: dev-machine
    user: laborant
    run: |
      # background setup that doesn't need to finish before student starts
```

### `regular` — Regular Task (user-facing)

The only type visible to students. Used to verify system conditions and check that student actions were performed correctly.

```yaml
tasks:
  verify_something:
    machine: dev-machine  # required if any task has machine (all or none)
    user: laborant
    needs:
      - verify_previous_task   # optional — runs after this task passes
    run: |
      # exit 0 = task passes (green)
      # exit 1 = task fails (red, retried)
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8500/file.cfm)
      if [ "${STATUS}" != "200" ]; then
        echo "file.cfm not accessible"
        exit 1
      fi
      echo "file.cfm is accessible ✓"
```

---

## Critical Rules (learned the hard way)

### machine property — all or nothing
> "either none or all tasks must have the `machine` property"

If **any** task has `machine:`, then **every** task must have `machine:`. You cannot mix tasks with and without it.

### Confirmed working schema (from foundations course — verified working)

```yaml
tasks:
  verify_something:
    machine: cf-dev        # must match playground.yaml machine name exactly
    user: laborant
    run: |
      ...shell script...

  verify_lesson_complete:
    machine: cf-dev
    user: laborant
    needs:
      - verify_something
    run: |
      echo "Lesson complete ✓"
```

Fields used: `machine`, `user`, `run`, `needs`. Nothing else.

### Do NOT invent fields

Fields confirmed **not** in the documentation:
- `timeout_seconds` — not documented, caused issues when added
- `init: true` on regular tasks — only valid on actual init tasks; adding it to all tasks caused the "Warming up playground" hang (Sep 2026)

---

## What "Warming up playground" means

The platform shows this screen with a counter ("Init tasks completed: 0/N") while init tasks are running. If it never clears:

1. An init task exited non-zero (script failure)
2. An init task is in an infinite loop (service never came up)
3. `init: true` was mistakenly added to tasks that should be regular tasks

The foundations course has **no init tasks** and works correctly — regular tasks simply run after the playground is up.

---

## Task Execution Flow

```
Playground starts
  └── All init tasks run in parallel
        └── All exit 0 → loading screen clears → regular tasks start running
        └── Any exit non-zero or hang → loading screen never clears
```

Regular tasks run automatically in a loop — students do not press a button. They pass when the script exits 0 and the UI task box turns green.

---

*Saved from iximiuz Labs documentation — Sep 20 2026*
*Critical notes added from debugging experience during advanced course authoring*

---

## Regular Verification Task

Definition is identical to an init task **except** there is no `init: true`. Regular tasks also require a corresponding `::simple-task` component in the content body.

### Front Matter definition

```yaml
tasks:
  verify_file_exists:
    machine: dev-machine
    # The only mandatory property of a regular task is the `run` script.
    # The task runs in a loop until it exits 0.
    run: |
      if [ ! -f /tmp/some/file.txt ]; then
        echo "Diagnostic message — not shown to student, useful for debugging."
        exit 1
      fi
```

- `run` is the **only mandatory property**
- The task executes in a **loop** until it exits 0 — then it turns green
- `echo` output in the run script is diagnostic only — students never see it
- Each regular task **must** have a visual representation in the content body (the `::simple-task` component)
- The total/done count of regular tasks is displayed in the content header as the main completion indicator

### Markdown representation — `::simple-task`

```markdown
::simple-task
---
:tasks: tasks
:name: <task-name>       ← must exactly match the task name in Front Matter
---
#active
<what needs to be done / what system condition needs to be met>

#completed
<what has been done or any other confirmation of completion>
::
```

### Full example

Front Matter:
```yaml
tasks:
  verify_file_exists:
    machine: dev-machine
    run: |
      if [ ! -f /tmp/some/file.txt ]; then
        exit 1
      fi
```

Content body:
```markdown
::simple-task
---
:tasks: tasks
:name: verify_file_exists
---
#active
Waiting for /tmp/some/file.txt to be created...

#completed
Nailed it! The file has appeared 🎉
::
```

### Key rules for `::simple-task`

- `:tasks: tasks` — always literally `tasks` (not the task name, not a variable)
- `:name:` — must **exactly** match the key in the `tasks:` block in Front Matter
- `#active` — shown while the task is still failing (student needs to act)
- `#completed` — shown once the task passes (exit 0)
- Never write "Hit Check" or "press Check" in `#active` — tasks run automatically in a loop, there is no button
- Good `#active` text: describes the file, URL, or exact condition the task is checking
- Good `#completed` text: short confirmation with ✓

---

## User-Input Task

An alternative way to visualize a regular task when the task requires the user to **submit specific data** (e.g. reading a value from a log). The input is validated and if correct, passed to the task for further processing.

> ⚠️ Full syntax for user-input tasks not yet documented here — paste the rest of the iximiuz docs page to complete this section.


---

## User-Input Task

Used when the task requires the user to **submit specific data** (e.g. reading a value from a log). Input is validated client-side and passed to the task script.

### Markdown component

```markdown
::user-input-task
---
:tasks: tasks
:name: <task-name>
:validateRegex: <optional regex — applied client-side before submission>
:destination: <optional path to store input in the playground VM>
---
#active
<what the user needs to enter>

#completed
<confirmation of completion>
::
```

### Example

```markdown
::user-input-task
---
:tasks: tasks
:name: input_container_name
:validateRegex: ^[0-9a-zA-Z-]{2,64}$
:destination: /tmp/container-name.txt
---
#active
Enter the name of the future container:

#completed
Nice one! You certainly have a good taste in names 🎉
::
```

### Corresponding Front Matter task

```yaml
tasks:
  input_container_name:
    machine: dev-machine
    run: |
      # User input is available via the x(.input) template variable.
      echo "x(.input)"

      # If destination is set, input is also stored in that file.
      cat /tmp/container-name.txt

      if [[ "x(.input)" != "my-awesome-container" ]]; then
        echo "The container name is not as awesome as it should be."
        exit 1
      fi

    hintcheck: |
      echo "The container name is not as awesome as it should be."
      echo "Try using 'my-awesome-container'."
```

**Key points:**
- `x(.input)` — template variable containing what the user typed
- `:destination:` — if set, input is also written to that file path in the VM
- `:validateRegex:` — client-side only, prevents invalid input from being submitted at all
- `hintcheck:` — optional script that runs to generate a hint for the student

---

## Task Dependencies (`needs`)

Tasks can depend on each other using `needs`. Dependent tasks run only after all listed tasks have passed.

```yaml
tasks:
  verify_container_is_running:
    machine: dev-machine
    needs:
      - input_container_name      # runs after this task passes
    env:
      # Pass data from a previous task using template variables:
      # x(.needs.task_name.stdout)
      # x(.needs.task_name.stderr)
      # x(.needs.task_name.exit_code)
      # x(.needs.task_name.input)    ← user input from a user-input-task
      # x(.needs.task_name.status)
      - CONTAINER_NAME=x(.needs.input_container_name.input)
    run: |
      if ! docker_container_is_running ${CONTAINER_NAME}; then
        echo "The container isn't running."
        exit 1
      fi
```

**Rules:**
- Regular tasks run only **after all init tasks** are completed
- By default regular tasks run in **parallel**
- `needs:` controls execution order and gives access to previous task output
- `env:` can use template variables from `needs` tasks

---

## Built-in Helper Functions

The task engine provides built-in shell helper functions available in every `run` script. Register your own by creating shell scripts in `/opt/iximiuz-labs/examiner/checks.d`.

### Docker

```bash
docker_container_name <id>           # container name
docker_container_pid <id>            # container PID
docker_container_ip <id>             # container IP
docker_container_image <id>          # image name
docker_container_image_id <id>       # image ID
docker_container_is_running <id>     # true/false
docker_container_exit_code <id>      # exit code
docker_container_count_total         # total container count
docker_container_count_running       # running container count
docker_image_id <name>               # image ID
docker_image_size_bytes <name>       # image size in bytes
```

### Podman

```bash
podman_container_name <id>
podman_container_pid <id>
podman_container_ip <id>
podman_container_is_running <id>
podman_container_exit_code <id>
podman_container_count_total
podman_container_count_running
```

### nerdctl

```bash
nerdctl_container_name <id>
nerdctl_container_pid <id>
nerdctl_container_ip <id>
nerdctl_container_is_running <id>
nerdctl_container_exit_code <id>
nerdctl_container_count_total
nerdctl_container_count_running
```

### ctr

```bash
ctr_container_netns <id>
ctr_container_pid <id>
ctr_container_is_running <id>
ctr_container_count_total
ctr_container_count_running
```

### Custom helpers

Place shell scripts in `/opt/iximiuz-labs/examiner/checks.d` to register your own helper functions available in all task `run` scripts.


---

## Play Variables (`vars`)

Tasks can feed values back into the content. Declared in the top-level `vars` Front Matter section, resolved inside the playground.

### Front Matter definition

```yaml
vars:
  # Fixed value
  PORT: "8080"

  # Value from task output — resolves when all referenced tasks complete
  NGINX_POD_IP: x(.tasks.init_lookup_nginx_ip.stdout)     # trimmed stdout of a task
  CONTAINER_NAME: x(.tasks.input_container_name.input)    # input from a user-input task
  URL: http://x(.vars.NGINX_POD_IP):x(.vars.PORT)/        # composed from other vars

  # One-off shell command — trimmed stdout becomes the value
  # Retried until exit 0, so it can wait for a service to come up
  SESSION_ID:
    shell: head -c4 /dev/urandom | od -An -tx1 | tr -d ' \n'
    machine: dev-machine    # optional; defaults to first machine of the playground
```

### Template variable syntax

| Expression | Resolves to |
|---|---|
| `x(.tasks.<name>.stdout)` | Trimmed stdout of the named task |
| `x(.tasks.<name>.stderr)` | Trimmed stderr of the named task |
| `x(.tasks.<name>.exit_code)` | Exit code of the named task |
| `x(.tasks.<name>.input)` | User input from a user-input task |
| `x(.tasks.<name>.status)` | Status of the named task |
| `x(.vars.<name>)` | Value of another declared var |

### Using vars in markdown

```markdown
<!-- Inline binding — shows fallback until resolved (single quotes only) -->
{{ vars.NAME || 'fallback shown until resolved' }}

<!-- Click-to-copy inline code element -->
:code-var{name=NAME default='placeholder'}
```

**Restrictions:**
- Bindings are **not** expanded inside inline code or code blocks — use `:code-var` for copyable values
- Bindings inside table cells **fail markdown validation** — use a list instead

### Using vars in task scripts

```yaml
tasks:
  some_task:
    env:
      - MY_VAR=x(.vars.NGINX_POD_IP)   # task stays blocked until var is resolved
    run: |
      echo "Connecting to ${MY_VAR}"
```

---

## Conditional Content

Shows the section matching the current value of a variable. The default (unnamed) section shows while the variable is unresolved or has no matching section.

```markdown
::conditional{var=CONTAINER_CHECK}
Complete the "container is running" task above to unlock this section.

#completed
Well done — here is the next part of the story...
::
```

> ⚠️ Content is delivered to the browser with the rest of the page — the gating is a **UX device, not a security boundary**. Do not put secrets or solutions here.

---

## Dynamic Hints (`hintcheck`) and Failure Conditions (`failcheck`)

### `hintcheck` — optional, non-blocking hint

Runs after the `run` script. Exit code has **no effect** on task outcome. stdout/stderr is shown in the task UI as a dynamic hint to the student.

### `failcheck` — optional, blocks the whole playground

Runs **before** the `run` script. If it exits non-zero, the task is marked **failed** and the **entire playground is marked failed** — the student must restart.

```yaml
tasks:
  verify_container_is_stopped:
    machine: dev-machine
    needs:
      - input_container_name
      - verify_container_is_running
    env:
      - CONTAINER_NAME=x(.needs.input_container_name.stdout)
    run: |
      if docker_container_is_running ${CONTAINER_NAME}; then
        echo "The container is still running."
        exit 1
      fi
      if ! docker ps -a | grep -q ${CONTAINER_NAME}; then
        echo "The container is completely gone."
        exit 1
      fi

    hintcheck: |
      # stdout/stderr shown as a hint in the task UI — exit code ignored
      if docker_container_is_running ${CONTAINER_NAME}; then
        echo "The container is still running."
        echo "Run 'docker stop ${CONTAINER_NAME}' to stop it."
      fi

    failcheck: |
      # If this exits non-zero → task FAILED → playground FAILED → student must restart
      if ! docker ps -a | grep -q ${CONTAINER_NAME}; then
        echo "The container has been removed. You shouldn't have done that!"
        echo "Please restart the tutorial and try again."
        exit 1
      fi
```

**Key distinction:**

| Script | When it runs | Exit code effect | Output shown to student |
|---|---|---|---|
| `run` | Main loop | non-zero = retry | No |
| `hintcheck` | After `run` | Ignored | Yes — as a hint |
| `failcheck` | Before `run` | non-zero = playground failed | Yes — as error message |

---

## Debugging Tasks

Tasks are executed by the `examinerd` daemon on each machine. By default it hides all stdout/stderr from task scripts.

**To access task output as a content author:**
- Use the `examinerctl` CLI tool on the playground machine
- Or click the **Tasks** button in the bottom-right corner of the playground to open the **Tasks Dev Tools** UI (visible to content authors only)

> Tasks Dev Tools are only available to the content author — students never see task output.

