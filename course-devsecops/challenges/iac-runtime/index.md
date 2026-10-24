---
kind: challenge

title: 'Apply, Posture-Scan, and Remediate (moto + Prowler)'

description: |
  Apply an OpenTofu config to a local AWS emulator (moto), scan the live
  emulated account with Prowler, remediate the flagged resource, and re-scan to
  show the finding cleared. The full static-to-runtime cloud security loop with
  entirely open-source tooling.

categories:
  - security
  - ci-cd

tagz:
  - moto
  - prowler
  - opentofu
  - devsecops

difficulty: hard

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-k8s-1ae0b5be

tasks:
  verify_moto:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5001/ 2>/dev/null || echo 000)
      if [ "${STATUS}" = "000" ]; then
        echo "moto_server not running on port 5001"
        exit 1
      fi
      echo "moto up"

  verify_applied:
    machine: dev-machine
    user: laborant
    needs:
      - verify_moto
    run: |
      FILE=/home/laborant/iac-rt/apply.log
      if [ ! -f "${FILE}" ]; then
        echo "apply.log not found"
        exit 1
      fi
      if ! grep -qiE "apply complete|added|created" "${FILE}"; then
        echo "apply.log does not show a successful apply"
        exit 1
      fi
      echo "applied"

  verify_first_scan:
    machine: dev-machine
    user: laborant
    needs:
      - verify_applied
    run: |
      FILE=/home/laborant/iac-rt/prowler-before.txt
      if [ ! -f "${FILE}" ]; then
        echo "prowler-before.txt not found — scan the account before remediation"
        exit 1
      fi
      echo "baseline scan present"

  verify_remediated_scan:
    machine: dev-machine
    user: laborant
    needs:
      - verify_first_scan
    run: |
      TF=/home/laborant/iac-rt/main.tf
      if grep -qi "public-read\|public-read-write" "${TF}"; then
        echo "The config still declares a public ACL — remediate it to private and re-apply"
        exit 1
      fi
      FILE=/home/laborant/iac-rt/prowler-after.txt
      if [ ! -f "${FILE}" ]; then
        echo "prowler-after.txt not found — re-scan after remediation"
        exit 1
      fi
      echo "remediated and re-scanned"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_remediated_scan
    run: |
      echo "Challenge complete!"
---

## The full cloud security loop

1. Start `moto_server` on port 5001.
2. Apply an OpenTofu config (pointed at moto) that creates an S3 bucket with a
   **public** ACL. Save output to `iac-rt/apply.log`.
3. Scan the live emulated account with Prowler; save the baseline to
   `iac-rt/prowler-before.txt`.
4. **Remediate:** change the ACL to `private` in `iac-rt/main.tf`, re-apply, and
   re-scan Prowler into `iac-rt/prowler-after.txt`.

::hint-box
---
:summary: The loop in commands
---
```bash
cd /home/laborant/iac-rt
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localhost:5001

tofu init && tofu apply -auto-approve | tee apply.log
prowler aws --service s3 --endpoint-url http://localhost:5001 > prowler-before.txt 2>&1

sed -i 's/public-read/private/' main.tf          # remediate
tofu apply -auto-approve | tee -a apply.log
prowler aws --service s3 --endpoint-url http://localhost:5001 > prowler-after.txt 2>&1
```
::

::simple-task
---
:tasks: tasks
:name: verify_moto
---
#active
Start `moto_server` on port 5001.

#completed
Emulator running. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_applied
---
#active
Apply the OpenTofu config against moto.

#completed
Infrastructure applied. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_first_scan
---
#active
Run a baseline Prowler scan into `prowler-before.txt`.

#completed
Baseline posture scan done. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_remediated_scan
---
#active
Set the ACL to private, re-apply, and re-scan into `prowler-after.txt`.

#completed
Remediated and verified on the live account. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you ran the full apply → scan → remediate → re-scan loop.

#completed
Runtime IaC posture challenge complete. ✓
::
