---
kind: challenge

title: 'Capstone: Commit to Deploy with Every Gate Active'

description: |
  A repository contains one planted security problem. Run the full DevSecOps
  pipeline — secret scan, SAST, image CVE scan, SBOM, signing — find and fix the
  problem, then deploy the signed image into a policy-gated namespace that only
  admits signed, compliant images.

categories:
  - security
  - ci-cd

tagz:
  - devsecops
  - pipeline
  - gitops
  - capstone

difficulty: hard

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-k8s-1ae0b5be

tasks:
  verify_scans_clean:
    machine: dev-machine
    user: laborant
    run: |
      REPO=/home/laborant/capstone-src
      if [ ! -d "${REPO}" ]; then
        echo "capstone-src not found"
        exit 1
      fi
      if ! gitleaks detect -s "${REPO}" --no-banner >/dev/null 2>&1; then
        echo "Gitleaks still finds a secret — remove and rotate it"
        exit 1
      fi
      if ! semgrep scan --config auto --error --severity ERROR "${REPO}" >/dev/null 2>&1; then
        echo "Semgrep still reports ERROR findings — fix them"
        exit 1
      fi
      echo "source gates clean"

  verify_image_signed:
    machine: dev-machine
    user: laborant
    needs:
      - verify_scans_clean
    run: |
      if ! cosign verify --key /home/laborant/cosign.pub localhost:5000/capstone:ci >/dev/null 2>&1; then
        echo "capstone image is not signed/verifiable"
        exit 1
      fi
      echo "image signed"

  verify_cve_gate:
    machine: dev-machine
    user: laborant
    needs:
      - verify_image_signed
    run: |
      if ! trivy image --quiet --exit-code 1 --ignore-unfixed --severity CRITICAL localhost:5000/capstone:ci >/dev/null 2>&1; then
        echo "capstone image still has fixable CRITICAL CVEs"
        exit 1
      fi
      echo "cve gate clean"

  verify_deployed:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cve_gate
    run: |
      if ! kubectl -n prod get deploy capstone >/dev/null 2>&1; then
        echo "capstone deployment not found in prod"
        exit 1
      fi
      READY=$(kubectl -n prod get deploy capstone -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
      if [ -z "${READY}" ] || [ "${READY}" -lt 1 ]; then
        echo "capstone has no ready replicas — did it pass the verifyImages policy?"
        exit 1
      fi
      echo "deployed and admitted"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_deployed
    run: |
      echo "Capstone complete!"
---

## The whole course, in one flow

The repo at `/home/laborant/capstone-src` has **one planted problem** (a secret,
an insecure code pattern, or a vulnerable base image — find out which). Take it
all the way to a running, policy-admitted deployment:

1. Run the source gates (Gitleaks, Semgrep). Fix whatever they flag; rotate any
   secret you find.
2. Build, scan (Trivy CVE), and generate an SBOM. Fix a CRITICAL fixable CVE if
   present (fresher base image).
3. Sign the image `localhost:5000/capstone:ci` with cosign.
4. Deploy it as `capstone` in the `prod` namespace, which runs a Kyverno
   `verifyImages` policy. It must become ready — meaning it passed the policy.

::hint-box
---
:summary: Strategy
---
Adapt your `pipeline.sh` from the lesson, pointing `REPO` at `capstone-src` and
the image at `localhost:5000/capstone:ci`. Run it; the first failing gate names
the planted problem. Fix it at the source (edit the file / bump the Dockerfile
base), re-run until all gates pass, then deploy. Remember: never silence a gate
to "make it pass" — the verifyImages policy at deploy will catch an unsigned
image anyway.
::

::simple-task
---
:tasks: tasks
:name: verify_scans_clean
---
#active
Make Gitleaks and Semgrep pass clean on `capstone-src`.

#completed
Source gates clean. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_image_signed
---
#active
Build and sign `localhost:5000/capstone:ci`.

#completed
Image signed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_cve_gate
---
#active
Pass the Trivy CRITICAL fixable-CVE gate.

#completed
CVE gate clean. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_deployed
---
#active
Deploy `capstone` to `prod` and confirm it is admitted and ready.

#completed
Signed, scanned image running in prod. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All gates green and deployed — you ran a full DevSecOps pipeline end to end.

#completed
Capstone complete. You're a DevSecOps practitioner now. ✓
::
