---
kind: unit

title: Runtime Threat Detection with Falco

name: runtime-detection-falco-unit-1
---

## Every control so far stops at deploy — attacks happen after

Pause and notice something about this whole course: scanning, policy, signing — every control you've built fires *before* the workload runs. They're superb at keeping bad things out. But what about the attacker who gets in anyway — through a zero-day, a stolen credential, or a supply-chain compromise that passed every scan? Once a container is running, your pre-deploy gates are blind to it.

**Falco** is the eye that stays open at runtime. It watches the **system calls** your containers make — the lowest-level actions, like opening a file, spawning a process, or opening a network connection — and raises an alert the instant something matches a suspicious pattern. "A shell was spawned inside a running container." "Something wrote to `/etc/passwd`." "A process connected to an unexpected IP." These are the signatures of an active intrusion, and Falco catches them live.

::image-box
---
:src: __static__/falco-runtime-v1.png
:alt: Diagram showing a running container issuing system calls to the Linux kernel; Falco taps the syscall stream via an eBPF probe, evaluates each event against a rule set, and emits an alert when a rule matches — an example alert box reads "Warning: shell spawned in container (user=root shell=bash container=app)"; a timeline shows pre-deploy controls (scan, policy, sign) ending at deploy and Falco covering the runtime period after
---
_Falco taps the kernel syscall stream and alerts on suspicious behavior — covering the runtime window that pre-deploy controls can't see._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tool:** Falco (Apache 2.0) — a CNCF runtime security project
- **Driver / microVM note:** Falco reads syscalls through a driver — a kernel module, classic eBPF, or **modern eBPF (CO-RE)**. In a Firecracker microVM, modern-eBPF is the right choice (no kernel module build). If the environment can't load an eBPF probe, Falco's **userspace**/`gvisor`-style or the `-M` simulated event path is used for the demo. The lab is configured so Falco can observe events; you focus on *writing rules and reading alerts*, not on driver setup.
- **Alternative:** Tetragon (Apache 2.0) is an eBPF runtime-security tool that can also *enforce*, not just detect.
- **Playground:** `devsecops-k8s`.
::

::hint-box
---
:summary: Detection vs prevention — doesn't Falco stopping it be better?
---
Falco's core job is **detection and alerting**, not blocking — and that's deliberate. Blocking at the syscall level risks killing legitimate processes and causing outages, so Falco raises a high-fidelity alert and lets your response tooling decide (page a human, kill the pod, isolate the node). Tools like Tetragon add *enforcement*. The DevSecOps pattern is: pre-deploy controls *prevent* known-bad; runtime detection *catches* the unknown-bad that slips through, fast enough to respond before real damage.
::

---

## 1. Confirm Falco is watching

**Activity — Terminal (dev):** Check that Falco is running and tailing events.

```bash
# Falco runs as a service in the lab
sudo systemctl status falco --no-pager | head -n 5 || pgrep -a falco

# Watch Falco's live output in one terminal (leave it running)
sudo journalctl -u falco -f &
```

::simple-task
---
:tasks: tasks
:name: verify_falco_running
---
#active
Confirm Falco is running (service active or process present).

#completed
Falco is watching the system. ✓
::

---

## 2. Trigger a classic alert: a shell in a container

One of Falco's default rules is **"Terminal shell in container"** — spawning an interactive shell inside a running container is a textbook sign of hands-on-keyboard intrusion.

**Activity — Terminal (dev):** Run a container, then exec a shell into it and watch Falco fire.

```bash
# Start a long-running container
docker run -d --name victim nginx:stable

# Spawn a shell inside it — this should trip Falco's default rule
docker exec -it victim bash -c "echo intruder; id"

# Capture the matching alert from Falco's log
sudo journalctl -u falco --no-pager | grep -i "shell" | tail -n 3 \
  | tee /home/laborant/falco-alert.txt
```

::hint-box
---
:summary: Why is "a shell in a container" treated as suspicious at all?
---
Containers are supposed to run *one* defined process — the app. Nobody should be opening an interactive `bash` inside a production container; there's no legitimate reason during normal operation. So while a shell is harmless in itself, its *appearance at runtime* is a strong signal that someone (an attacker, or an operator doing something risky) is poking around by hand. Falco turns "something that should never happen" into an immediate alert. The art of runtime rules is picking behaviors that are rare-and-bad.
::

::simple-task
---
:tasks: tasks
:name: verify_alert_captured
---
#active
Trigger a shell-in-container event and save the matching Falco alert to `/home/laborant/falco-alert.txt`.

#completed
You captured a live runtime alert. ✓
::

---

## 3. Write a custom rule

Default rules are a starting point. Real value comes from rules tuned to *your* app's normal behavior.

**Activity — Terminal (dev):** Write a custom rule that alerts when anything writes to a sensitive path.

```bash
cat > /home/laborant/falco-rule.yaml << 'EOF'
- rule: Write to sensitive app config
  desc: Detect writes to /app/config at runtime, which should be immutable
  condition: >
    evt.type in (open, openat, openat2) and evt.is_open_write=true
    and fd.name startswith /app/config
  output: >
    Sensitive config write (user=%user.name command=%proc.cmdline file=%fd.name
    container=%container.name)
  priority: WARNING
  tags: [filesystem, integrity]
EOF

cat /home/laborant/falco-rule.yaml
```

::hint-box
---
:summary: What are condition, output, and priority doing?
---
A Falco rule is three key parts. **`condition`** is a filter over syscall fields (`evt.type`, `fd.name`, `proc.cmdline`, `container.name` …) — it decides *when* the rule fires. **`output`** is the alert message, with `%field` placeholders filled from the event, so responders get context (who, what command, which file, which container). **`priority`** (EMERGENCY…DEBUG) sets severity, which downstream tools use for routing — page on CRITICAL, log on NOTICE. Good rules are specific enough to avoid noise and rich enough that the alert alone tells the responder what happened.
::

::simple-task
---
:tasks: tasks
:name: verify_custom_rule
---
#active
Write a custom Falco rule to `/home/laborant/falco-rule.yaml`.

#completed
Your custom runtime rule is written. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **Runtime security** | Detecting threats while workloads are running |
| **Falco** | CNCF tool that alerts on suspicious syscall behavior |
| **System call** | Lowest-level action (open, exec, connect) Falco observes |
| **eBPF driver** | How Falco taps syscalls safely (modern eBPF / CO-RE) |
| **Rule: condition/output/priority** | When it fires / the message / severity |
| **Detection vs enforcement** | Falco alerts; Tetragon can block |
| **Shell-in-container** | Classic intrusion signal and default rule |
| **Pre-deploy vs runtime** | Gates prevent known-bad; Falco catches the rest live |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Detección en runtime con Falco**

- Todos los controles anteriores (escaneo, política, firma) actúan **antes** de ejecutar. ¿Y el atacante que entra igual — por un 0-day o una credencial robada? Una vez el contenedor corre, los controles previos están ciegos.
- **Falco** vigila las **llamadas al sistema** (syscalls) de los contenedores y alerta al instante ante patrones sospechosos: "se abrió una shell dentro de un contenedor", "se escribió en `/etc/passwd`", "conexión a una IP inesperada".
- Falco **detecta y alerta**, no bloquea (bloquear a nivel syscall arriesga cortes). Herramientas como Tetragon añaden *enforcement*.
- En un microVM se usa el driver **modern-eBPF** (sin compilar módulo de kernel). Tú te centras en *escribir reglas y leer alertas*.
- Disparaste la regla por defecto "shell en contenedor", capturaste la alerta, y escribiste una regla propia (`condition`/`output`/`priority`) para detectar escrituras en una ruta sensible.
::

---

## Now Prove It

The challenge asks you to trigger a runtime alert, capture it, and write a custom rule that detects a behavior specific to the scenario.

::card
---
:challenge: challenges.falco-runtime-d71c2b5f
---
::
