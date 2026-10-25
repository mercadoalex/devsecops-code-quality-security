---
kind: lesson

title: LLM Security — Prompt Injection & Garak
description: |
  The OWASP LLM Top 10, why prompt injection is the signature LLM vulnerability,
  how to serve a small local model with Ollama, scan it for weaknesses with
  Garak, and mitigate prompt injection with layered defenses.

name: llm-security-garak
slug: llm-security-garak

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- programming

tagz:
- llm
- garak
- ollama
- prompt-injection

playground:
  name: devsecops-ai-7fdb7fbb

challenges:
  garak-llm-scan-006d06fe: {}

tasks:
  verify_ollama:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient service state,
      # so this task only turns green after the learner actually probes Ollama.
      FILE=/home/laborant/ollama-check.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the curl check in the Terminal (dev) tab"
        exit 1
      fi
      if [ ! -s "${FILE}" ]; then
        echo "${FILE} is empty — re-run the curl check"
        exit 1
      fi
      # Double-check the Ollama API really is up (the marker could be stale).
      if ! curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        echo "Ollama API not responding on 11434"
        exit 1
      fi
      echo "ollama ok and confirmed by the student"
    hintcheck: |
      echo "Run this exact command in the Terminal (dev) tab:"
      echo "  curl -s http://localhost:11434/api/tags | tee /home/laborant/ollama-check.txt"

  verify_model_pulled:
    machine: dev-machine
    user: laborant
    needs:
      - verify_ollama
    run: |
      if ! curl -s http://localhost:11434/api/tags | grep -qi "qwen2.5"; then
        echo "qwen2.5 model not pulled"
        exit 1
      fi
      echo "model present"
    hintcheck: |
      echo "Pull the small model:  ollama pull qwen2.5:0.5b"

  verify_injection_demo:
    machine: dev-machine
    user: laborant
    needs:
      - verify_model_pulled
    run: |
      FILE=/home/laborant/injection-demo.txt
      if [ ! -f "${FILE}" ]; then
        echo "injection-demo.txt not found"
        exit 1
      fi
      echo "injection demo recorded"
    hintcheck: |
      echo "Send a prompt-injection attempt to the model and save the exchange to injection-demo.txt."

  verify_garak_started:
    machine: dev-machine
    user: laborant
    needs:
      - verify_model_pulled
    run: |
      if [ ! -f /home/laborant/garak-run/started.txt ] && [ -z "$(ls -A /home/laborant/.local/share/garak/garak_runs 2>/dev/null)" ]; then
        echo "no evidence a Garak run was started"
        exit 1
      fi
      echo "garak started"
    hintcheck: |
      echo "Kick off a scoped Garak run (it continues in the background) and note it in /home/laborant/garak-run/started.txt."

  verify_mitigation_notes:
    machine: dev-machine
    user: laborant
    needs:
      - verify_injection_demo
    run: |
      FILE=/home/laborant/llm-mitigations.md
      if [ ! -f "${FILE}" ]; then
        echo "llm-mitigations.md not found"
        exit 1
      fi
      if ! grep -qiE "prompt injection|system prompt|validate|guardrail|least privilege" "${FILE}"; then
        echo "llm-mitigations.md should list prompt-injection mitigations"
        exit 1
      fi
      echo "mitigations documented"
    hintcheck: |
      echo "Write /home/laborant/llm-mitigations.md listing prompt-injection defenses."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_garak_started
      - verify_mitigation_notes
    run: |
      echo "Lesson complete — well done!"
---
