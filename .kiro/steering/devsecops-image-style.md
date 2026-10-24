---
inclusion: manual
---

# DevSecOps Course — Image Style Contract & Prompt Template

The single source of truth for every diagram and illustration in the
**DevSecOps: Code Quality & Security** course. All 17 in-lesson diagrams and any
future visuals MUST be generated from the template below so the course has one
coherent visual identity. Do not invent a new style per image.

The course cover (`course-devsecops/__static__/cover.png`) already sets the
reference look: navy/teal with cyan + emerald accents, clean isometric-ish flat
style, soft light background, security framed as good engineering (not threat).

---

## Style contract (applies to EVERY image)

**Audience & mood:** the course is for companies and institutions; it is
technical. Mood is **institutional, precise, calm, authoritative** — never
alarmist, never playful.

**Visual language:**
- Clean flat-vector / soft-3D infographic. Clean geometric shapes, rounded
  corners, subtle depth and soft shadows.
- Background: **white or soft light gray** (`#F7F9FB`-ish). Never dark/dystopian.
- Palette: **deep navy + teal base, with cyan highlights and emerald-green
  success accents.** Red used ONLY sparingly and only to denote a cost/risk
  curve or a rejected/blocked state — never as a general "danger/alarm" wash.
- Colors are welcome, but must not lose focus — one clear subject per image.
- Security is shown as **shields, check badges, gates, padlocks-with-checkmarks** —
  the "verification/clean energy" read, not fear.

**Hard NOs (reject any output that includes these):**
- Course title, headings, or sub-headings baked into the image (the lesson
  supplies its own — only the short LABELS may appear)
- Fire, flames, embers, glowing heat (use a red gradient for "expensive/risk")
- Cartoonish or mascot elements
- Neon colors; organic textures; hand-drawn / sketchy feel
- Hand-made or decorative typography
- Watermarks, agency seals, rank insignia, decorative borders
- Readable body text / gibberish text baked into the image (short labels only,
  see below)
- Skulls, hooded hackers, matrix rain, glitch, warning-triangle spam

**Exceptions require approval — ask, don't silently discard.** Everything on the
Hard-NO list is forbidden by default. But a loaded element may occasionally be
*intentional and useful* — for example a flame to flag a critical finding, or an
attacker/hacker figure to depict a threat-model actor. So when a generated image
contains a Hard-NO element (flames, hacker figures, a baked title, a red alarm
wash, or any edge case):

1. **Do NOT ship it automatically, and do NOT silently throw it away.**
2. **Stop and ask Alex**: show the image, name the element, and say whether it
   looks accidental (generator noise) or like it might be communicating something
   the lesson needs.
3. **Wait for Alex's decision** — regenerate without it, or keep it as an
   approved exception.
4. If approved, note the exception inline in that prompt so the deviation is
   traceable, and (optionally) keep the element only where it carries meaning.

The default is still "clean, no Hard-NO elements"; this rule just ensures a
potentially-meaningful element is reviewed by Alex rather than auto-removed.

**Text in images:** keep to **short, real labels only** (phase names, stage
names, 1–3 word tags). No sentences, no paragraphs. **Do NOT render the course
title, any heading, or any sub-heading inside the image** — the lesson supplies
its own title and caption; a baked title is off-style and redundant. Only draw
the exact labels listed in the prompt's LABELS slot. Image generators mangle long
text and tend to paint the framing sentence onto the canvas — forbid that
explicitly in every prompt.

**Rising cost / risk:** when a curve or region must read as "expensive" or
"high risk", use a **solid red or deep-red gradient only**. **Never draw fire,
flames, embers, or glowing heat** — those are on the Hard-NO list and break the
calm, authoritative mood.

**Format:** 16:9 landscape, `max-width: 860px` in-lesson (cover is 1200x630).
Export PNG. File naming stays `<concept>-<descriptor>-v<N>.png` (increment `vN`,
never overwrite).

---

## The template prompt (fill the three ALL-CAPS slots)

Paste this into the image generator, replacing only `SUBJECT`, `ELEMENTS`, and
`LABELS`. Everything else is fixed so the set stays coherent.

```
A clean, modern technical infographic for an enterprise DevSecOps course titled
"DevSecOps: Code Quality & Security". Institutional, precise, calm, authoritative
mood — security shown as good engineering, never as threat.

SUBJECT: <one sentence: what the diagram shows and its single focus>

ELEMENTS: <the concrete shapes/flow to draw — boxes, arrows, nodes, icons, and
how they connect>

LABELS (short, real text only — no sentences): <the 1–3 word labels to place>

Visual language: flat-vector meets soft 3D, clean geometric shapes, rounded
corners, subtle depth and soft shadows. Security motifs are shields, check
badges, gates, and padlock-with-checkmark icons.

Color palette: soft light background (white or very light blue-grey); deep NAVY
and TEAL as the base; CYAN highlights; EMERALD-GREEN success accents. Use RED
only if a cost/risk curve or a rejected/blocked state is explicitly required,
and only for that element — never as a general alarm wash.

Composition: one clear subject, generous negative space, balanced, crisp edges,
no grain. 16:9 landscape.

Strictly avoid: cartoonish or mascot elements, neon colors, organic textures,
hand-drawn or sketchy feel, hand-made or decorative typography, watermarks,
agency seals, rank insignia, decorative borders, readable paragraphs or gibberish
text, skulls, hooded hackers, matrix rain, glitch, flames, warning-triangle spam.

High detail, professional, enterprise-grade. Aspect ratio 16:9.
```

---

## Worked example — Module 1 L1: Shift-Left (`shift-left-sdlc-v1.png`)

```
A clean, modern technical infographic for an enterprise DevSecOps course titled
"DevSecOps: Code Quality & Security". Institutional, precise, calm, authoritative
mood — security shown as good engineering, never as threat.

SUBJECT: the software development lifecycle as a left-to-right pipeline, with a
"Shift-Left" arrow pulling security earlier, and a cost-of-fixing curve rising
toward the late phases.

ELEMENTS: a horizontal row of five connected rounded-rectangle phase nodes left
to right — Plan, Code, Build, Test, Deploy — joined by a clean teal arrow. A
single curved CYAN arrow arcs from the Deploy phase back toward Plan/Code,
labelled "Shift-Left". Beneath the row, a smooth cost curve rises gently under
the early phases and steeply under the late phases; its low (early) end tinted
emerald-green, its high (late) end tinted red to signal rising cost. Small
shield-with-check badges sit above the early phases to show security moving left.

LABELS (short, real text only — no sentences): Plan, Code, Build, Test, Deploy,
Shift-Left, Cost to fix.

Visual language: flat-vector meets soft 3D, clean geometric shapes, rounded
corners, subtle depth and soft shadows. Security motifs are shields, check
badges, gates, and padlock-with-checkmark icons.

Color palette: soft light background (white or very light blue-grey); deep NAVY
and TEAL as the base; CYAN highlights; EMERALD-GREEN success accents. Use RED
only for the high (late, expensive) end of the cost curve — never as a general
alarm wash.

Composition: one clear subject, generous negative space, balanced, crisp edges,
no grain. 16:9 landscape.

Strictly avoid: cartoonish or mascot elements, neon colors, organic textures,
hand-drawn or sketchy feel, hand-made or decorative typography, watermarks,
agency seals, rank insignia, decorative borders, readable paragraphs or gibberish
text, skulls, hooded hackers, matrix rain, glitch, flames, warning-triangle spam.

High detail, professional, enterprise-grade. Aspect ratio 16:9.
```

> Caption (goes in the lesson, NOT in the image): _"The later a defect is found,
> the more it costs to fix. Shift-Left moves security checks toward the cheap end
> of the curve."_

---

## Workflow for each image

1. Open the lesson's `.png.todo` — it already describes the intended content.
2. Fill the template's `SUBJECT` / `ELEMENTS` / `LABELS` from that `.todo`.
3. Generate, review against the **Hard NOs**, regenerate if any appear.
4. Save as `<concept>-<descriptor>-v1.png` in the lesson's `__static__/`, drop the
   `.png.todo`.
5. Confirm the lesson's `:alt:` text still matches what the final image shows.
