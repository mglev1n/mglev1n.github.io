# Design Prototypes — Levin Lab Website

**Date:** 2026-02-28
**Scope:** CSS-only redesign prototypes for mglev1n.github.io (Quarto-generated site)

## Goal

Prototype 3 distinct visual styles for the Levin Lab website to evaluate before committing to a redesign of `styles.css`. Prototypes are delivered as a single standalone `prototype.html` file — no Quarto render required — so all designs can be compared in one browser window.

## Constraints

- CSS-only changes (no JS, no modifications to `.qmd` files)
- Must work with the existing Quarto minimal HTML output structure
- Key HTML landmarks: `h1` (lab name), `h2` (section headings), `h3` (publication year), `#refs-index` (publications on index), `.csl-entry`, `.footer`
- Content on prototype page matches actual site content

## Design Variants

### Design 1 — Editorial Serif

- **Typography:** Georgia serif, h1 44px weight 700 with tight letter-spacing
- **Subtitle:** Uppercase/small-caps label in muted gray, generous spacing
- **Research overview:** Left-border accent (`border-left: 3px solid #222`)
- **Publications:** Full-width rule separator, muted gray for the section
- **Palette:** Near-black (#1a1a1a) + warm gray (#888) + off-white background
- **Feel:** Academic journal meets long-form editorial (Nature, NEJM)

### Design 2 — Modern Sans

- **Typography:** System sans-serif (`-apple-system`, `Inter`), h1 40px weight 800
- **Research overview:** Light tinted container (`#f5f5f5` bg, subtle border-radius 8px, padding 28px)
- **Section headers:** Small uppercase with letter-spacing
- **Publications:** Card-style rows with thin left rule per entry
- **Palette:** White + light gray + `#0055cc` links
- **Feel:** Clean software-company docs (linear.app, stripe)

### Design 3 — Bold Typographic

- **Typography:** h1 56px+ weight 900, tight tracking (-2px)
- **Header:** Dark accent band (near-black bg, white text) containing title + subtitle
- **Body column:** Slightly wider (900px)
- **Publications:** Compact numbered list with year callouts in accent color
- **Palette:** #111 header + white body + single vivid accent (e.g. `#c0392b` or `#0055cc`)
- **Feel:** Expressive university department redesign

## Deliverable

`prototype.html` — self-contained file in the worktree root. All 3 designs stacked vertically with clear labels. Same real content in each. Open directly in browser, no server needed.

## Next Step

After reviewing prototypes, select the preferred design (or mix of elements) and update `styles.css` in the main repo.
