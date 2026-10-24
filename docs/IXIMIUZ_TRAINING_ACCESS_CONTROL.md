# iximiuz Labs — Instructor-Led Training Access Control

Source: https://labs.iximiuz.com/docs/content-authoring/instructor-led-training-access

> Prerequisite: read `IXIMIUZ_ACCESS_CONTROL.md` first — this page builds on top of it.

---

## How It Works

Enrolling in a training automatically grants the student a special role:

```
student:<training-name>
```

where `<training-name>` is the last segment of the training URL.

**Our training name:** `coldfusion-tags-to-tokens-0ebc2ee3`
**Our student role:** `student:coldfusion-tags-to-tokens-0ebc2ee3`

---

## Lifecycle

1. You create the training — it gets a unique name from the URL
2. You share the training landing page with students
3. Student enrolls from that page (optionally requires your approval)
4. Once enrolled + approved + training window is open → student holds the role
5. Role is **automatically revoked** when training ends (if end date is set)

---

## Gating Content to Students Only

For each piece of content to reserve for the training, set:

```yaml
canList: [owner]
canRead: [student:coldfusion-tags-to-tokens-0ebc2ee3]
canStart: [student:coldfusion-tags-to-tokens-0ebc2ee3]
```

Effect:
- Stays out of all public catalogs (`canList: [owner]`)
- Only enrolled students can read it and start its playground
- Everyone else (including logged-in non-students) is denied

> ⚠️ The playground has its own access control — must also grant `canStart` to the same `student:` role. Otherwise students can read the content but not start the playground.

---

## Our Playground Access — What to Set

Both playgrounds must grant the student role on `canStart`:

**`cf-training-devops-3039c6bb`** (Modules 1–3, 5):
```yaml
canList: [owner]
canRead: [anyone]
canStart: [student:coldfusion-tags-to-tokens-0ebc2ee3]
```

**`cf-training-advanced-7442b9e0`** (Module 4 — AI/Ollama):
```yaml
canList: [owner]
canRead: [anyone]
canStart: [student:coldfusion-tags-to-tokens-0ebc2ee3]
```

---

## Common Access Recipes for Training Content

### Fully gated — students only
```yaml
canList: [owner]
canRead: [student:coldfusion-tags-to-tokens-0ebc2ee3]
canStart: [student:coldfusion-tags-to-tokens-0ebc2ee3]
```

### Free preview — anyone can read, only students can start
```yaml
canList: [owner]
canRead: [anyone]
canStart: [student:coldfusion-tags-to-tokens-0ebc2ee3]
```
Use this for "teaser" lessons (e.g. Module 1 Lesson 1) that you want publicly readable but require enrollment to actually do.

### Public and listed (free lesson, no restriction)
```yaml
canList: [anyone]
canRead: [anyone]
canStart: [anyone]
```

---

## Important Notes

- **Time-gated:** The `student:` role is only active while the training is active. Students lose access when the end date passes (unless you explicitly allow post-end access).
- **Enrollment approval:** You can require manual approval before enrollment becomes active — controlled in the training's Configure dialog.
- **`__static__/` is NOT protected** — CDN-served, no auth checks. Never put student-only files there.

---

## Our Training Configuration — What to Fix

Current `canEnroll: owner` causes **"Enrollment closed"** for all students.

**Fix in the Configure dialog** (UI only, no labctl):

| Field | Current | Change to |
|---|---|---|
| `canEnroll` | `owner` | `authenticated` (open enrollment) or leave as `owner` and manually approve |
| `canList` | `authenticated` | keep |
| `canRead` | `anyone` | keep |

---

## Per-Lesson Access in the `lessons:` Block

> **Status: not documented in either guide.**
> The `lessons: {}` field appears in the training Configure dialog but neither
> the content access guide nor the instructor-led training guide explains its syntax.
> Contact iximiuz Labs support for clarification before editing this field.

---

*Saved from iximiuz Labs documentation — Sep 20 2026*
