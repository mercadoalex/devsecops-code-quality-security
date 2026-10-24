---
inclusion: manual
---

# iximiuz Labs — Access Control

---

## Overview

Every piece of content (Tutorial, Challenge, Course, Lesson, Playground) uses
the same access control model. Configured from the content's menu in the UI —
no frontmatter or `labctl` changes required. Every draft starts private
(`[owner]` on all dimensions).

---

## Access dimensions

| Field | Controls |
|-------|----------|
| `canList` | Whether content appears in public catalogs |
| `canPreview` | Limited preview without full access (tutorials, skill paths) |
| `canRead` | Who can read the full content body |
| `canStart` | Who can start the playground and mark content complete |
| `canReadSolution` | Who can read the challenge solution (challenges only) |
| `canEnroll` | Who can enroll in a training |

---

## Roles

| Role | Grants access to |
|------|-----------------|
| `owner` | Only you (the author) — default for every dimension |
| `anyone` | Everyone including anonymous visitors |
| `authenticated` | Any logged-in iximiuz user |
| `github:<handle>` | A specific GitHub account |
| `student:<training-name>` | Everyone enrolled in the named training |

Multiple roles in one dimension = access granted if requester matches **any** of them.

---

## Common recipes

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

### Public but unlisted (share by URL only)
```yaml
canList: [owner]
canRead: [anyone]
canStart: [anyone]
```

### Training students only
```yaml
canList: [owner]
canRead: [student:<training-name>]
canStart: [student:<training-name>]
```

### Free preview — anyone reads, only students start
```yaml
canList: [owner]
canRead: [anyone]
canStart: [student:<training-name>]
```
Use this for "teaser" lessons: publicly readable, but requires enrollment to do.

---

## Instructor-led training

Enrolling in a training grants the role `student:<training-name>` where
`<training-name>` is the last URL segment of the training.

**Lifecycle:**
1. Create training → platform assigns a unique name
2. Share the training landing page with students
3. Student enrolls (optionally requires your approval)
4. Role is active while training window is open
5. Role is **automatically revoked** when training end date passes

**Fix "Enrollment closed" error:** Change `canEnroll` from `owner` to
`authenticated` in the Configure dialog (UI only, no `labctl` command).

---

## Playground access is separate

The playground you attach has its own access control. Make sure it is at least
as permissive as the content — otherwise students who can read the content can't
start it.

For a training, both playgrounds must grant `canStart` to the `student:` role:

```yaml
# In playground Configure dialog
canList: [owner]
canRead: [anyone]
canStart: [student:<training-name>]
```

---

## Important notes

- **`__static__/` files are NOT protected** — served via CDN with no auth checks.
  Anyone can fetch them if they know the URL. Never put student-only content there.
- **Non-English content** is not listed in main catalogs even with `canList: [anyone]`.
- `canList: [anyone]` signals willingness to be listed — actual catalog placement
  is curated by the iximiuz team.

---

## Playground manifest access control

Valid principal names (in playground YAML `accessControl` block):
```
owner
anyone
authenticated
github:<handle>
student:<training-name>
```

Invalid (causes HTTP 400 or silent failure):
```
role:registered    ← invalid
role:author        ← invalid
```

---

## `labctl` push notes

Always use `-f` (force) flag when pushing updates:

```bash
# Push course
labctl content push -f course <course-slug> -d course-N

# Push challenge
labctl content push -f challenge <challenge-slug> -d challenges/<name>
```

Without `-f`, `labctl` detects existing content and prompts interactively.
When no TTY is available (CI, piped, or certain terminal states) it silently
skips all files — the push appears to succeed but nothing is updated.

---

## Quick reference: verify what's live

```bash
# See all published content
labctl content list

# See registered playgrounds
labctl playground list

# Pull what the platform actually has (works for drafts)
labctl content pull course <slug> -d /tmp/verify-pull
```
