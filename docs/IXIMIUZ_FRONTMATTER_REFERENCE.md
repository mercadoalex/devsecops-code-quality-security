# iximiuz Labs — Supported Front Matter Fields

Source: iximiuz Labs content authoring documentation.

---

## Tutorial

```yaml
---
kind: tutorial         # fixed

title: <string>        # required, 10-120 characters
description: <string>  # required, up to 500 characters

# Up to 2 categories from the closed list:
# - linux
# - networking
# - containers
# - kubernetes
# - programming
# - observability
# - security
# - ci-cd
categories:            # required
  - category-1
  - category-2

# Up to 5 tags, preferably from the already existing ones:
# curl https://labs.iximiuz.com/api/content/tags?kind=tutorial
tagz:                  # required
  - tag-1
  - tag-2

createdAt: <string>    # required, format: YYYY-MM-DD[THH:MM:SS]
updatedAt: <string>    # optional, format: YYYY-MM-DD[THH:MM:SS]

cover: <image filename from the __static__ folder>  # required

playground:            # optional
  name: <string>
  machines: ...
  tabs: ...

tasks:                 # optional
  task_name_1:
    ...
  task_name_2:
    ...

challenges:            # optional
  challenge-name-1: {}
  challenge-name-2: {}

playgrounds:           # optional
  playground-name-1: {}
  playground-name-2: {}

tutorials:             # optional
  tutorial-name-1: {}
  tutorial-name-2: {}

skill-paths:           # optional
  skill-path-name-1: {}
  skill-path-name-2: {}
---
```

---

## Notes

- `tagz` (not `tags`) is the correct field name — using `tags` is silently ignored
- `categories` values must come from the closed list above — unknown values cause validation errors
- `createdAt` / `updatedAt` must be **bare dates** (`2026-09-03`), never quoted strings (`"2026-09-03"`) — quoted strings cause the platform YAML parser to silently ignore the `tasks:` block entirely (discovered Sep 2026 during advanced course authoring)
- `cover` must reference a file that actually exists in `__static__/` — missing covers cause the lesson to render without a thumbnail but do not break the lesson itself
- `playground.name` must match a registered playground name exactly — use `labctl playground list` to verify

---

## Quick reference — fetch existing tags

```bash
# Tutorial tags
curl https://labs.iximiuz.com/api/content/tags?kind=tutorial

# Challenge tags
curl https://labs.iximiuz.com/api/content/tags?kind=challenge

# Course tags
curl https://labs.iximiuz.com/api/content/tags?kind=course
```

---

*Saved from iximiuz Labs documentation — Sep 20 2026*
