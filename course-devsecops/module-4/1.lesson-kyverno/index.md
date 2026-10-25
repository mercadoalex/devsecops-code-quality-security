---
kind: lesson

title: Policy-as-Code with Kyverno
description: |
  The OWASP Kubernetes Top 10, why admission control is where cluster security
  is enforced, and how to write Kyverno policies that block insecure workloads
  before they run — starting with "no privileged, no running as root".

name: policy-as-code-kyverno
slug: policy-as-code-kyverno

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- kubernetes

tagz:
- kyverno
- policy-as-code
- admission-control
- devsecops

playground:
  name: devsecops-k8s-1ae0b5be

challenges:
  kyverno-policy-a193dfe4: {}

tasks:
  verify_cluster_ready:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient cluster state,
      # so this task only turns green after the learner actually queries the cluster.
      FILE=/home/laborant/cluster-check.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the node check in the Terminal (dev) tab"
        exit 1
      fi
      if ! grep -q "Ready" "${FILE}"; then
        echo "${FILE} does not show a Ready node — re-run the node check"
        exit 1
      fi
      # Double-check the cluster really is reachable (the marker could be stale).
      if ! kubectl get nodes >/dev/null 2>&1; then
        echo "Kubernetes cluster not reachable"
        exit 1
      fi
      echo "cluster ready and confirmed by the student"
    hintcheck: |
      echo "Run this exact command in the Terminal (dev) tab:"
      echo "  kubectl get nodes | tee /home/laborant/cluster-check.txt"

  verify_kyverno_installed:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cluster_ready
    run: |
      if ! kubectl get ns kyverno >/dev/null 2>&1; then
        echo "kyverno namespace not found"
        exit 1
      fi
      if ! kubectl -n kyverno get deploy >/dev/null 2>&1; then
        echo "kyverno not installed"
        exit 1
      fi
      echo "kyverno present"
    hintcheck: |
      echo "Kyverno is pre-installed in the kyverno namespace. Check:  kubectl -n kyverno get pods"

  verify_policy_applied:
    machine: dev-machine
    user: laborant
    needs:
      - verify_kyverno_installed
    run: |
      if ! kubectl get clusterpolicy disallow-privileged >/dev/null 2>&1; then
        echo "clusterpolicy disallow-privileged not found"
        exit 1
      fi
      echo "policy applied"
    hintcheck: |
      echo "Apply your ClusterPolicy:  kubectl apply -f /home/laborant/disallow-privileged.yaml"

  verify_privileged_blocked:
    machine: dev-machine
    user: laborant
    needs:
      - verify_policy_applied
    run: |
      OUT=$(kubectl run badpod --image=nginx --privileged --dry-run=server 2>&1 || true)
      if ! echo "${OUT}" | grep -qiE "disallow-privileged|blocked|not allowed|validation|denied"; then
        echo "A privileged pod was not blocked by the policy"
        exit 1
      fi
      echo "privileged pod blocked"
    hintcheck: |
      echo "Your ClusterPolicy must deny pods with privileged: true in enforce mode."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_privileged_blocked
    run: |
      echo "Lesson complete — well done!"
---
