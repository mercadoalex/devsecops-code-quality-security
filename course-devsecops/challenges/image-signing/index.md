---
kind: challenge

title: 'Sign and Verify a Container Image'

description: |
  Generate a cosign key pair, sign an image in the local registry, prove the
  signature verifies, and show that an unsigned image fails verification —
  the integrity-and-provenance gate for your supply chain.

categories:
  - security
  - ci-cd

tagz:
  - cosign
  - image-signing
  - supply-chain
  - devsecops

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-k8s-1ae0b5be

tasks:
  verify_keypair:
    machine: dev-machine
    user: laborant
    run: |
      if [ ! -f /home/laborant/cosign.key ] || [ ! -f /home/laborant/cosign.pub ]; then
        echo "cosign key pair not found"
        exit 1
      fi
      echo "keypair ok"

  verify_signed:
    machine: dev-machine
    user: laborant
    needs:
      - verify_keypair
    run: |
      cd /home/laborant
      if ! cosign verify --key cosign.pub localhost:5000/app:signed >/dev/null 2>&1; then
        echo "localhost:5000/app:signed does not verify against cosign.pub"
        exit 1
      fi
      echo "signed image verifies"

  verify_unsigned_fails:
    machine: dev-machine
    user: laborant
    needs:
      - verify_signed
    run: |
      cd /home/laborant
      if cosign verify --key cosign.pub localhost:5000/app:unsigned >/dev/null 2>&1; then
        echo "An unsigned image unexpectedly verified — it must fail"
        exit 1
      fi
      echo "unsigned image correctly fails"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_unsigned_fails
    run: |
      echo "Challenge complete!"
---

## Prove provenance

1. Generate a cosign key pair in `/home/laborant`.
2. Push and **sign** an image as `localhost:5000/app:signed`.
3. Push a second image **without signing** it as `localhost:5000/app:unsigned`.
4. Show that `cosign verify` **succeeds** on the signed image and **fails** on
   the unsigned one.

::hint-box
---
:summary: Commands
---
```bash
cd /home/laborant
COSIGN_PASSWORD="" cosign generate-key-pair
docker pull alpine:3.20
docker tag alpine:3.20 localhost:5000/app:signed
docker tag alpine:3.20 localhost:5000/app:unsigned
docker push localhost:5000/app:signed
docker push localhost:5000/app:unsigned
COSIGN_PASSWORD="" cosign sign --key cosign.key --yes localhost:5000/app:signed
cosign verify --key cosign.pub localhost:5000/app:signed      # succeeds
cosign verify --key cosign.pub localhost:5000/app:unsigned    # fails (no signature)
```
::

::simple-task
---
:tasks: tasks
:name: verify_keypair
---
#active
Generate a cosign key pair.

#completed
Key pair ready. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_signed
---
#active
Sign `localhost:5000/app:signed` and confirm it verifies.

#completed
Signed image verifies. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_unsigned_fails
---
#active
Confirm `localhost:5000/app:unsigned` fails verification.

#completed
Unsigned image correctly rejected. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — signed passes, unsigned fails.

#completed
Image signing challenge complete. ✓
::
