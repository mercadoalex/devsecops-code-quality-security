---
kind: lesson

title: Image Signing & GitOps Delivery
description: |
  Keyless image signing with cosign, why a signature proves provenance and
  integrity, how Kyverno can refuse unsigned images at admission, and how GitOps
  with Argo CD makes Git the single source of truth for what runs in the cluster.

name: image-signing-gitops
slug: image-signing-gitops

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- ci-cd

tagz:
- cosign
- image-signing
- gitops
- argocd

playground:
  name: devsecops-k8s-1ae0b5be

challenges:
  image-signing-93f4df06: {}

tasks:
  verify_cosign:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient PATH,
      # so this task only turns green after the learner actually checks the version.
      FILE=/home/laborant/cosign-version.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the version check in the Terminal (dev) tab"
        exit 1
      fi
      if [ ! -s "${FILE}" ]; then
        echo "${FILE} is empty — re-run the version check"
        exit 1
      fi
      # Double-check cosign really is on PATH (the marker could be stale).
      if ! command -v cosign >/dev/null 2>&1; then
        echo "cosign not found"
        exit 1
      fi
      echo "cosign ok and confirmed by the student"
    hintcheck: |
      echo "Run this exact command in the Terminal (dev) tab:"
      echo "  cosign version | tee /home/laborant/cosign-version.txt"

  verify_keypair:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cosign
    run: |
      if [ ! -f /home/laborant/cosign.key ] || [ ! -f /home/laborant/cosign.pub ]; then
        echo "cosign key pair not found"
        exit 1
      fi
      echo "keypair ok"
    hintcheck: |
      echo "Generate a key pair:  cosign generate-key-pair (in /home/laborant)"

  verify_signature:
    machine: dev-machine
    user: laborant
    needs:
      - verify_keypair
    run: |
      FILE=/home/laborant/verify-output.txt
      if [ ! -f "${FILE}" ]; then
        echo "verify-output.txt not found"
        exit 1
      fi
      if ! grep -qi "verified\|signature" "${FILE}"; then
        echo "verify-output.txt should show a successful signature verification"
        exit 1
      fi
      echo "signature verified"
    hintcheck: |
      echo "Sign an image, then 'cosign verify' it with your public key and save the output."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_signature
    run: |
      echo "Lesson complete — well done!"
---
