#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Install the AI/LLM-security toolchain:
#   Ollama (CPU-only) with qwen2.5:0.5b BAKED IN, and Garak.
# Run as root during docker build. Builds on the slim vmbase.
#
# Size discipline (all in this single layer so deletions actually shrink the
# image): strip Ollama's bundled GPU runtime libs (~2.3 GB, useless CPU-only),
# keep only the service-user model store, and wipe pip/pipx/model caches.
# -----------------------------------------------------------------------------
set -euo pipefail
LAB_USER="${LAB_USER:-laborant}"
MODEL="qwen2.5:0.5b"

# The Ollama installer needs zstd to extract its archive.
echo "== ensure zstd =="
command -v zstd >/dev/null 2>&1 || { apt-get update && apt-get install -y zstd && rm -rf /var/lib/apt/lists/*; }

echo "== Ollama =="
curl -fsSL https://ollama.com/install.sh | sh
systemctl enable ollama 2>/dev/null || true

echo "== strip GPU runtime libraries (CPU-only lab — no GPU in Firecracker) =="
# Ollama bundles large CUDA/ROCm libs we can never use. Remove them.
du -sh /usr/local/lib/ollama 2>/dev/null || true
rm -rf /usr/local/lib/ollama/cuda* \
       /usr/local/lib/ollama/rocm* \
       /usr/local/lib/ollama/*cuda* \
       /usr/local/lib/ollama/*rocm* 2>/dev/null || true
echo "after strip:"; du -sh /usr/local/lib/ollama 2>/dev/null || true

echo "== Bake the small model (${MODEL}) =="
OLLAMA_HOST=127.0.0.1:11434 nohup ollama serve > /tmp/ollama-build.log 2>&1 &
OLLAMA_PID=$!
for i in $(seq 1 30); do
  curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1 && break || sleep 2
done
ollama pull "${MODEL}" || echo "WARN: model pull failed (student will pull on first run)"
kill "${OLLAMA_PID}" 2>/dev/null || true
sleep 2

echo "== Keep ONLY the service-user model store (drop the /root duplicate) =="
# The systemd ollama unit runs as the 'ollama' user and reads /usr/share/ollama.
if [ -d /root/.ollama ]; then
  mkdir -p /usr/share/ollama/.ollama
  cp -a /root/.ollama/. /usr/share/ollama/.ollama/ 2>/dev/null || true
  chown -R ollama:ollama /usr/share/ollama/.ollama 2>/dev/null || true
  rm -rf /root/.ollama        # drop the ~380 MB duplicate
fi

echo "== Garak via pipx (force CPU-only torch to avoid multi-GB CUDA wheels) =="
# Garak depends on torch/transformers. By default pip pulls the CUDA build of
# torch (~5+ GB) — useless in a CPU-only microVM. Install garak, then replace
# torch with the CPU wheel inside garak's pipx venv, shrinking it by ~5 GB.
sudo -u "${LAB_USER}" bash -lc 'pipx install garak || pipx upgrade garak'
sudo -u "${LAB_USER}" bash -lc '
  pipx runpip garak uninstall -y torch torchvision torchaudio 2>/dev/null || true
  pipx runpip garak install --no-cache-dir \
    --index-url https://download.pytorch.org/whl/cpu torch \
    || echo "WARN: CPU torch install failed — garak may still work for remote-model probes"
'

echo "== clean caches (pip, pipx build, model tmp, apt) =="
rm -rf /root/.cache /tmp/* /var/tmp/* 2>/dev/null || true
sudo -u "${LAB_USER}" bash -lc 'rm -rf ~/.cache/pip ~/.cache/pipx' 2>/dev/null || true
rm -rf /var/lib/apt/lists/*
echo "ai-tools install complete (model ${MODEL} baked, GPU libs stripped, caches cleaned)"
