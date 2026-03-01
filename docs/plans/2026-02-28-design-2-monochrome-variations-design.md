# Design 2 Monochrome Variations — Design Doc

**Date:** 2026-02-28
**Scope:** Append 3 new monochrome high-contrast variations of Design 2 to the existing `prototype.html`

## Goal

Add Variations 2A, 2B, 2C to `prototype.html` as additional sections below the existing 3 designs. All three are CSS-only, monochrome (no hues), and push contrast/visual distinctness further than the original Design 2.

## Approach

Append to `prototype.html` (no structural changes to existing designs). Three new `.design-2a`, `.design-2b`, `.design-2c` sections with scoped CSS. Same sticky label bar + white proto-frame pattern as existing designs.

## Variation Specs

### 2A — Inverted Research Block

Start from Design 2 baseline. Single inversion: the `.research-block` becomes dark.

- **Research block:** `background: #111; color: #fff; border-radius: 10px; padding: 28px 32px`
- **Research block links:** `color: #fff; text-decoration: underline`
- **Publications separator:** `border-top: 3px solid #111; padding-top: 20px; margin-top: 40px`
- **Publication entries:** Keep `border-left: 2px solid #555` (slightly darker than original #e0e0e0)
- **All links:** `color: #111; text-decoration: underline; text-underline-offset: 2px`
- **Everything else:** Identical to Design 2 (same font, sizes, spacing)

### 2B — Weight Contrast + Ruled Sections

No background fills anywhere. Contrast from weight and rules only.

- **Body text:** `font-weight: 300`
- **h1:** 40px, `font-weight: 800` (same as Design 2 — contrast is h1 vs body weight)
- **Research overview:** Bounded by `border-top: 2px solid #111; border-bottom: 2px solid #111; padding: 24px 0; margin: 28px 0` — no background
- **h3 (Selected Publications):** `font-weight: 700; font-size: 11px; text-transform: uppercase; letter-spacing: 3px; color: #111`
- **Publication entries:** `border-left: 4px solid #111; padding-left: 16px; margin: 16px 0` — no background
- **All links:** `color: #111; text-decoration: underline; text-underline-offset: 2px`
- **No `.research-block` wrapper** — the research paragraphs are direct children of `.content` with no container

### 2C — Data-Table Publications

Research block stays light gray (Design 2 baseline). Publications get a structured table treatment.

- **Research block:** Same as Design 2 (`background: #f6f6f6; border-radius: 10px; padding: 28px 32px`)
- **Publications section header bar:** `.pub-header { background: #111; color: #fff; padding: 10px 16px; margin-top: 40px; margin-bottom: 0; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: 3px }`
- **Publication entries:** `border-bottom: 1px solid #ddd; padding: 14px 0; margin: 0` — no left border rule
- **`#refs-index` container:** `border: 1px solid #ddd; border-top: none; padding: 0 16px`
- **All links:** `color: #111; text-decoration: underline; text-underline-offset: 2px`

## HTML Notes

- Use `id="refs-index-2a"`, `id="refs-index-2b"`, `id="refs-index-2c"` to avoid duplicate ID issues
- Variation 2B: do NOT wrap research paragraphs in `.research-block` — they are plain `<p>` tags directly in `.content`, enclosed only by the ruled container div (use a `<div class="research-ruled">` wrapper with the border rules)
- Variation 2C: add `<div class="pub-header">Selected Publications</div>` before `#refs-index-2c` instead of using the `<h3>` element (or keep h3 and style it with the black bar treatment)
