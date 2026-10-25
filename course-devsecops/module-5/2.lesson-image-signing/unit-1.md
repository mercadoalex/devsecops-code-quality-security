---
kind: unit

title: Image Signing & GitOps Delivery

name: image-signing-gitops-unit-1
---

## How do you know the image you deploy is the one you built?

Your pipeline builds an image and pushes it to a registry. Days later your cluster pulls `myapp:1.4` and runs it. Between those two moments, how do you *know* nobody swapped the image, poisoned the registry, or slipped in a tampered layer? A tag is just a mutable label — `latest` today is not `latest` tomorrow. You need cryptographic proof.

**Signing** provides it. With **cosign** you sign an image after building it; the signature is stored alongside the image in the registry. At deploy time, anyone with your public key can **verify** that the image is exactly what you signed and came from you. Pair that with a Kyverno policy that *refuses unsigned images*, and tampered or unknown images simply cannot run.

::image-box
---
:src: __static__/cosign-signing-v1.png
:alt: Diagram showing a CI pipeline building an image and cosign producing a signature stored next to the image in the registry; at deploy time the Kubernetes cluster pulls the image and a Kyverno verifyImages policy checks the signature against a trusted public key, admitting the image if the signature is valid and rejecting it if missing or invalid
---
_cosign signs the image at build time; a Kyverno verifyImages policy checks the signature at admission and rejects anything unsigned or tampered._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tools:** cosign (Apache 2.0) for signing/verifying; Kyverno (Apache 2.0) for `verifyImages`; Argo CD (Apache 2.0) for GitOps (introduced conceptually)
- **Why it fits our microVM:** cosign is a tiny Go binary; signing is a fast cryptographic operation against a local registry. We use a local registry so nothing leaves the VM.
- **Playground:** `devsecops-k8s`.
::

::hint-box
---
:summary: Keyed vs keyless signing — which are we doing?
---
cosign supports two modes. **Keyed** uses a key pair you generate and manage — simple and self-contained, which is what we use in the lab. **Keyless** (the modern default in CI) uses short-lived certificates from Sigstore's Fulcio tied to an OIDC identity (your GitHub Actions workflow, say), with the signature logged in a public transparency log (Rekor) — no long-lived private key to leak. Keyless is best for real pipelines; keyed is clearer for learning the mechanics, so we start there.
::

---

## 1. Generate a key pair and sign an image

**Activity — Terminal (dev):** Create a cosign key pair and sign a local image.

```bash
cd /home/laborant
# Record the version so the lab can confirm YOU ran this step
cosign version | tee /home/laborant/cosign-version.txt

# Generate a key pair (set an empty password for the lab)
COSIGN_PASSWORD="" cosign generate-key-pair

# Push a small image to the lab's local registry, then sign it
docker pull alpine:3.20
docker tag alpine:3.20 localhost:5000/alpine:signed
docker push localhost:5000/alpine:signed

COSIGN_PASSWORD="" cosign sign --key cosign.key --yes localhost:5000/alpine:signed
```

> ⏱️ The push and sign take a few seconds against the local registry.

::simple-task
---
:tasks: tasks
:name: verify_cosign
---
#active
Run `cosign version` to confirm the tool is installed — the check records it to `/home/laborant/cosign-version.txt`.

#completed
cosign is ready. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_keypair
---
#active
Generate a cosign key pair (`cosign.key` + `cosign.pub`) in `/home/laborant`.

#completed
Key pair generated. ✓
::

---

## 2. Verify the signature

**Activity — Terminal (dev):** Verify the image against your public key and save the proof.

```bash
cd /home/laborant
cosign verify --key cosign.pub localhost:5000/alpine:signed | tee /home/laborant/verify-output.txt
```

A successful verification proves two things at once: **integrity** (the image hasn't changed since signing) and **provenance** (it was signed by the holder of your private key).

::hint-box
---
:summary: Where does the signature actually live?
---
cosign stores the signature as an extra artifact in the **same registry**, under a tag derived from the image's digest (e.g. `sha256-...sig`). There's no separate signature database to run. This is why signing works with any OCI registry you already use — the signature travels with the image. Verification fetches that artifact and checks it against your key.
::

::simple-task
---
:tasks: tasks
:name: verify_signature
---
#active
Verify the signed image with your public key and save the output to `/home/laborant/verify-output.txt`.

#completed
The signature verified — integrity and provenance confirmed. ✓
::

---

## 3. Enforce signatures with Kyverno (concept + demo)

Signing is only half the story. The other half is *refusing to run anything unsigned*. Kyverno has a `verifyImages` rule for exactly this.

**Activity — Terminal (dev):** Apply a policy that requires images to carry a valid signature from your key.

```bash
cat > /home/laborant/require-signed.yaml << 'EOF'
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-signed-images
spec:
  validationFailureAction: Enforce
  rules:
    - name: verify-signature
      match:
        any:
          - resources:
              kinds: [Pod]
      verifyImages:
        - imageReferences:
            - "localhost:5000/*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |-
                      # paste the contents of cosign.pub here in a real run
EOF

echo "This policy template shows how Kyverno rejects unsigned images at admission."
echo "In enforce mode, a pod using an unsigned localhost:5000 image is denied."
```

::hint-box
---
:summary: How does this connect to GitOps and Argo CD?
---
**GitOps** means the desired state of your cluster lives in Git, and a controller continuously reconciles the cluster to match it. **Argo CD** is that controller: you commit a manifest, Argo CD notices and applies it — no human running `kubectl` against prod. The security win is huge: every change is a reviewed, audited Git commit, and drift is auto-corrected. Combined with signed images and a verifyImages policy, the chain is airtight: only reviewed manifests (GitOps) referencing signed images (cosign) that pass policy (Kyverno) ever run. We introduce Argo CD conceptually here; the capstone wires the pieces together.
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **Image signing** | Cryptographic proof of integrity + provenance |
| **cosign** | Sigstore tool to sign and verify OCI artifacts |
| **Keyed vs keyless** | Managed key pair vs short-lived Sigstore certs (Fulcio/Rekor) |
| **`cosign sign` / `verify`** | Produce / check a signature |
| **Kyverno `verifyImages`** | Admission rule that rejects unsigned/untrusted images |
| **GitOps** | Desired cluster state lives in Git, continuously reconciled |
| **Argo CD** | GitOps controller that applies Git state to the cluster |
| **Provenance** | Assurance of where an artifact came from |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Firma de imágenes y entrega GitOps**

- Una etiqueta (`:latest`) es mutable: no prueba que la imagen que despliegas sea la que construiste. La **firma** aporta prueba criptográfica de **integridad** (no cambió) y **procedencia** (la firmaste tú).
- Con **cosign** firmas la imagen tras construirla; la firma se guarda junto a la imagen en el registry. Cualquiera con tu clave pública la **verifica**.
- Modos: **con clave** (par que gestionas — usado en el lab) y **keyless** (certificados efímeros de Sigstore/Fulcio + log Rekor, ideal para CI).
- Una política **`verifyImages` de Kyverno** rechaza imágenes sin firmar en admisión. Combinado con **GitOps/Argo CD** (el estado del clúster vive en Git y se reconcilia solo), la cadena queda cerrada: solo manifiestos revisados, con imágenes firmadas, que pasan la política, llegan a ejecutarse.
- Generaste un par de claves, firmaste una imagen y verificaste la firma.
::

---

## Now Prove It

The challenge asks you to sign an image, verify it, and show that a tampered or unsigned reference fails verification.

::card
---
:challenge: challenges.image-signing-93f4df06
---
::
