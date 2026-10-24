---
kind: lesson

title: End-to-End DevSecOps Pipeline
description: |
  Wire every control you've learned into one pipeline — secret scan, SAST,
  image CVE scan, SBOM, signing, and an admission policy that only admits
  signed, policy-compliant images. Take a change from commit to deploy with
  every gate active.

name: end-to-end-pipeline
slug: end-to-end-pipeline

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- ci-cd

tagz:
- devsecops
- pipeline
- gitops
- capstone

playground:
  name: devsecops-k8s-1ae0b5be

challenges:
  devsecops-capstone-56f65b95: {}

tasks:
  verify_pipeline_script:
    machine: dev-machine
    user: laborant
    run: |
      FILE=/home/laborant/pipeline.sh
      if [ ! -f "${FILE}" ]; then
        echo "pipeline.sh not found"
        exit 1
      fi
      for stage in gitleaks semgrep trivy cosign; do
        if ! grep -qi "${stage}" "${FILE}"; then
          echo "pipeline.sh is missing the ${stage} stage"
          exit 1
        fi
      done
      echo "pipeline script ok"
    hintcheck: |
      echo "Write /home/laborant/pipeline.sh chaining gitleaks, semgrep, trivy, and cosign stages."

  verify_pipeline_runs:
    machine: dev-machine
    user: laborant
    needs:
      - verify_pipeline_script
    run: |
      FILE=/home/laborant/pipeline-run.log
      if [ ! -f "${FILE}" ]; then
        echo "pipeline-run.log not found — run the pipeline and capture its output"
        exit 1
      fi
      if ! grep -qiE "pass|ok|signed|complete" "${FILE}"; then
        echo "pipeline-run.log does not show a successful run"
        exit 1
      fi
      echo "pipeline ran"
    hintcheck: |
      echo "Run the pipeline and save its output:  bash pipeline.sh | tee pipeline-run.log"

  verify_signed_image_deployed:
    machine: dev-machine
    user: laborant
    needs:
      - verify_pipeline_runs
    run: |
      if ! kubectl get deploy app -n prod >/dev/null 2>&1; then
        echo "Deployment app not found in namespace prod"
        exit 1
      fi
      READY=$(kubectl -n prod get deploy app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
      if [ -z "${READY}" ] || [ "${READY}" -lt 1 ]; then
        echo "app deployment has no ready replicas (was it admitted by policy?)"
        exit 1
      fi
      echo "signed image deployed and running"
    hintcheck: |
      echo "Deploy the signed image to the prod namespace; it must pass the verifyImages policy."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_signed_image_deployed
    run: |
      echo "Lesson complete — well done!"
---
