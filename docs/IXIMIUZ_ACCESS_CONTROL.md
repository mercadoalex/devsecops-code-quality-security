# iximiuz Labs — Access Control Guide

Source: https://labs.iximiuz.com/docs/content-authoring/access-control

---

## Overview

Every piece of content (Tutorial, Challenge, Course, Skill Path, Roadmap, Playground) uses the same access control model. Access is configured from the content's menu in the UI — **no front matter or labctl changes required**.

Every draft starts private — all dimensions default to `[owner]`.

---

## Access Dimensions

| Field | Controls | Applies to |
|---|---|---|
| `canList` | Whether content appears in public catalogs | all kinds |
| `canPreview` | Who can see a limited preview without full access | tutorials, skill paths |
| `canRead` | Who can read the full content body | all kinds |
| `canStart` | Who can start the playground and mark content complete | all kinds |
| `canReadSolution` | Who can read the challenge solution | challenges only |

Dimensions are independent — mix and match freely.

---

## Roles

| Role | Who it grants access to |
|---|---|
| `owner` | Only you (the author). Default for every dimension. |
| `anyone` | Everyone including anonymous visitors and bots. |
| `authenticated` | Any logged-in iximiuz Labs user (not anonymous). |
| `github:<handle>` | A specific GitHub account (e.g. `github:octocat`). |
| `student:<training-name>` | Everyone enrolled in the named training. |

Multiple roles in one dimension = access granted if requester matches **any** of them.

---

## Common Recipes

### Private (default)
```yaml
canList: [owner]
canRead: [owner]
canStart: [owner]
```

### Public and listed
```yaml
canList: [anyone]
canRead: [anyone]
canStart: [anyone]
```
> Note: `canList: [anyone]` is only a signal of willingness — iximiuz team curates actual catalog listings.

### Public but unlisted (share by URL only)
```yaml
canList: [owner]
canRead: [anyone]
canStart: [anyone]
```

### Specific named users only
```yaml
canList: [owner]
canRead: [github:alice, github:bob]
canStart: [github:alice, github:bob]
```

### Any logged-in user
```yaml
canList: [owner]
canRead: [authenticated]
canStart: [authenticated]
```

### Training students only (most powerful)
```yaml
canList: [owner]
canRead: [student:my-awesome-course-2026]
canStart: [student:my-awesome-course-2026]
```
Enrollment and revocation managed automatically. Covered in the instructor-led training access guide.

---

## Important Notes

- **Playground access is separate.** The playground you attach has its own access control. Make sure it is at least as permissive as the content — otherwise users who can read the content won't be able to start it.
- **`__static__` files are NOT protected.** Files in `__static__/` are served via CDN with no authorization checks. Anyone can fetch them with URL guessing. **Never put sensitive or student-only files in `__static__/`.**
- **Non-English content** is not listed in main catalogs even if `canList: [anyone]`.

---

## Our Training Setup — `coldfusion-tags-to-tokens-0ebc2ee3`

Current state (as of Sep 20 2026):

| Field | Value | Effect |
|---|---|---|
| `canList` | `authenticated` | Only logged-in users see it in listings |
| `canRead` | `anyone` | Anyone can read it |
| `canReadProgram` | `anyone` | Anyone can read the program |
| `canPreviewProgram` | `anyone` | Anyone can preview the program |
| `canEnroll` | `owner` | **Only the author can enroll — causes "Enrollment closed" for everyone else** |

**Fix:** Change `canEnroll` to `authenticated` in the Configure dialog.

---

## Per-Lesson Access Control (`lessons:` block)

> **Status: syntax unknown — not documented on the access control page.**
> The `lessons: {}` field appears in the training Configure dialog but the per-lesson
> syntax is covered in a separate "instructor-led training access guide" (not yet read).
> Do NOT edit the `lessons:` block until that guide is reviewed.
> URL to check: https://labs.iximiuz.com/docs/content-authoring/instructor-led-training-access

---

*Saved from iximiuz Labs documentation — Sep 20 2026*
