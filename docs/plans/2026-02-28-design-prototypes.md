# Design Prototypes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a standalone `prototype.html` file that renders the Levin Lab website content in 3 distinct CSS design variants, stacked vertically for side-by-side comparison.

**Architecture:** One self-contained HTML file with all CSS inlined. Three `<section class="designN">` wrappers each contain identical site content. CSS is scoped per section via descendant selectors (`.design-1 h1`, `.design-2 h1`, etc.) so all three can coexist without conflicts.

**Tech Stack:** Plain HTML5 + CSS3. No JS, no build step. Open `prototype.html` directly in a browser.

---

### Task 1: Create the HTML scaffold

**Files:**
- Create: `prototype.html` (in worktree root: `.claude/worktrees/design-prototypes/`)

**Step 1: Write the scaffold**

Create `prototype.html` with this exact structure:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Levin Lab — Design Prototypes</title>
  <style>
    /* ── Reset ────────────────────────────────────── */
    *, *::before, *::after { margin: 0; padding: 0; box-sizing: border-box; }

    /* ── Prototype chrome ─────────────────────────── */
    body { background: #d0d0d0; }

    .proto-label {
      background: #222;
      color: #fff;
      font-family: monospace;
      font-size: 13px;
      padding: 10px 24px;
      letter-spacing: 1px;
    }

    .proto-frame {
      background: #fff;
      margin-bottom: 0;
    }

    /* ── Design 1 styles ──────────────────────────── */
    /* (added in Task 2) */

    /* ── Design 2 styles ──────────────────────────── */
    /* (added in Task 3) */

    /* ── Design 3 styles ──────────────────────────── */
    /* (added in Task 4) */
  </style>
</head>
<body>

  <div class="proto-label">DESIGN 1 — Editorial Serif</div>
  <div class="proto-frame">
    <div class="design-1">
      <!-- content added in Task 2 -->
    </div>
  </div>

  <div class="proto-label">DESIGN 2 — Modern Sans</div>
  <div class="proto-frame">
    <div class="design-2">
      <!-- content added in Task 3 -->
    </div>
  </div>

  <div class="proto-label">DESIGN 3 — Bold Typographic</div>
  <div class="proto-frame">
    <div class="design-3">
      <!-- content added in Task 4 -->
    </div>
  </div>

</body>
</html>
```

**Step 2: Verify the file opens**

Open `prototype.html` in a browser. Expected: dark gray page with 3 black label bars and white frames (empty for now).

---

### Task 2: Design 1 — Editorial Serif

**Files:**
- Modify: `prototype.html`

**Step 1: Add the shared content block**

The Quarto output produces HTML close to this structure. Use it for all three designs (copy identically into each `.design-N` wrapper):

```html
<div class="content">
  <h1>Levin Lab</h1>
  <h2>Cardiovascular genetics research at the University of Pennsylvania</h2>

  <p>We study the genetic basis of cardiovascular disease using large-scale biobanks and electronic health records.</p>

  <p>Our research characterizes how common and rare genetic variation shapes susceptibility to cardiovascular diseases. We use these discoveries to identify therapeutic targets, develop genetic risk prediction tools, and conduct mechanistic clinical studies to validate findings in humans.</p>

  <p>We work with the <a href="#">Million Veteran Program</a>, <a href="#">Penn Medicine Biobank</a>, and other population-scale cohorts using computational genetics, epidemiologic methods, and clinical/translational approaches.</p>

  <h3>Selected Publications</h3>

  <div id="refs-index">
    <div class="csl-entry">
      Levin MG, Tsao NL, Singhal P, et al. Genome-wide association analysis identifies novel loci for coronary artery disease and improves genomic prediction.
      <i>Nat Genet.</i> 2025;57(3):412–421.
    </div>
    <div class="csl-entry">
      Levin MG, Libby P, Inouye M. Genetic architectures of cardiovascular and cardiometabolic traits.
      <i>Circulation.</i> 2024;149(18):1423–1436.
    </div>
    <div class="csl-entry">
      Levin MG, Rader DJ. Genetics of coronary artery disease: practical implications.
      <i>JACC.</i> 2023;82(12):1185–1197.
    </div>
  </div>

  <p><a href="#">View all publications →</a></p>

  <p><a href="#">Contact</a> | <a href="#">GitHub</a></p>

  <div class="footer">Last updated: February 28, 2026</div>
</div>
```

Place this HTML inside `<div class="design-1">`.

**Step 2: Add Design 1 CSS**

Inside the `<style>` block, replace the `/* Design 1 styles */` comment with:

```css
/* ── Design 1: Editorial Serif ────────────────── */
.design-1 {
  font-family: Georgia, 'Times New Roman', serif;
  font-size: 17px;
  line-height: 1.6;
  color: #1a1a1a;
  max-width: 760px;
  margin: 0 auto;
  padding: 52px 32px 48px;
  text-align: justify;
}

.design-1 h1 {
  font-size: 44px;
  font-weight: 700;
  letter-spacing: -1.5px;
  line-height: 1.05;
  margin-bottom: 10px;
}

.design-1 h2 {
  font-size: 13px;
  font-weight: 400;
  text-transform: uppercase;
  letter-spacing: 2.5px;
  color: #888;
  margin-bottom: 36px;
  margin-top: 2px;
}

.design-1 h3 {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 3px;
  color: #aaa;
  margin-top: 40px;
  margin-bottom: 18px;
  padding-bottom: 0;
  border-bottom: none;
}

.design-1 .content > p:first-of-type,
.design-1 p {
  margin: 16px 0;
}

.design-1 .content > p:nth-of-type(1) {
  border-left: 3px solid #1a1a1a;
  padding-left: 20px;
  font-size: 18px;
  line-height: 1.5;
  margin-bottom: 20px;
}

.design-1 #refs-index {
  color: #555;
  border-top: 2px solid #1a1a1a;
  padding-top: 16px;
}

.design-1 .csl-entry {
  margin: 14px 0;
  line-height: 1.5;
  font-size: 15px;
}

.design-1 a {
  color: #1a1a1a;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.design-1 a:hover {
  color: #555;
}

.design-1 .footer {
  margin-top: 48px;
  padding-top: 16px;
  border-top: 1px solid #ddd;
  font-size: 13px;
  color: #999;
}
```

**Step 3: Verify in browser**

Reload `prototype.html`. Design 1 should show: large serif title, small-caps subtitle in gray, first paragraph with left accent rule, muted publications section.

---

### Task 3: Design 2 — Modern Sans

**Files:**
- Modify: `prototype.html`

**Step 1: Add content to Design 2**

Copy the same content block (from Task 2 Step 1) into `<div class="design-2">`. Identical HTML, different CSS class wrapper.

**Step 2: Add Design 2 CSS**

Replace `/* Design 2 styles */` comment with:

```css
/* ── Design 2: Modern Sans ────────────────────── */
.design-2 {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', sans-serif;
  font-size: 16px;
  line-height: 1.65;
  color: #111;
  max-width: 800px;
  margin: 0 auto;
  padding: 56px 32px 56px;
}

.design-2 h1 {
  font-size: 40px;
  font-weight: 800;
  letter-spacing: -1px;
  line-height: 1.1;
  margin-bottom: 8px;
}

.design-2 h2 {
  font-size: 13px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: #999;
  margin-bottom: 40px;
  margin-top: 4px;
}

.design-2 h3 {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2.5px;
  color: #bbb;
  margin-top: 0;
  margin-bottom: 14px;
  border-bottom: none;
  padding-bottom: 0;
}

.design-2 .content > p {
  margin: 14px 0;
  color: #333;
}

.design-2 .research-block {
  background: #f6f6f6;
  border-radius: 10px;
  padding: 28px 32px;
  margin: 28px 0;
}

.design-2 #refs-index {
  color: #555;
  margin-top: 40px;
  padding-left: 0;
  padding-right: 0;
}

.design-2 .csl-entry {
  border-left: 2px solid #e0e0e0;
  padding-left: 16px;
  margin: 16px 0;
  font-size: 14.5px;
  line-height: 1.6;
  color: #555;
}

.design-2 a {
  color: #0055cc;
  text-decoration: none;
}

.design-2 a:hover {
  text-decoration: underline;
}

.design-2 .footer {
  margin-top: 52px;
  padding-top: 16px;
  border-top: 1px solid #eee;
  font-size: 13px;
  color: #aaa;
}
```

**Step 3: Wrap research paragraphs in Design 2**

In the `<div class="design-2">` content, wrap the three research `<p>` tags in:

```html
<div class="research-block">
  <p>We study the genetic basis…</p>
  <p>Our research characterizes…</p>
  <p>We work with the…</p>
</div>
```

Note: this only applies to the `.design-2` content block — do NOT add `.research-block` to Design 1 or Design 3 content.

**Step 4: Verify in browser**

Reload. Design 2 should show: bold sans-serif title, research overview in a light gray rounded container, publications as card-style rows with left accent lines.

---

### Task 4: Design 3 — Bold Typographic

**Files:**
- Modify: `prototype.html`

**Step 1: Add content to Design 3**

Copy the same content block into `<div class="design-3">`. Wrap the h1 and h2 in a `.hero` div:

```html
<div class="design-3">
  <div class="hero">
    <div class="hero-inner">
      <h1>Levin Lab</h1>
      <p class="hero-sub">Cardiovascular genetics research at the University of Pennsylvania</p>
    </div>
  </div>
  <div class="content">
    <!-- h2 removed here since it's in hero; start with the paragraphs -->
    <p>We study the genetic basis…</p>
    <p>Our research characterizes…</p>
    <p>We work with the…</p>
    <h3>Selected Publications</h3>
    <div id="refs-index">…</div>
    <p><a href="#">View all publications →</a></p>
    <p><a href="#">Contact</a> | <a href="#">GitHub</a></p>
    <div class="footer">Last updated: February 28, 2026</div>
  </div>
</div>
```

**Step 2: Add Design 3 CSS**

Replace `/* Design 3 styles */` comment with:

```css
/* ── Design 3: Bold Typographic ───────────────── */
.design-3 {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', sans-serif;
  font-size: 17px;
  line-height: 1.6;
  color: #111;
  max-width: 100%;
}

.design-3 .hero {
  background: #111;
  color: #fff;
  padding: 64px 0 56px;
}

.design-3 .hero-inner {
  max-width: 900px;
  margin: 0 auto;
  padding: 0 40px;
}

.design-3 h1 {
  font-size: 64px;
  font-weight: 900;
  letter-spacing: -3px;
  line-height: 0.95;
  margin-bottom: 18px;
  color: #fff;
}

.design-3 .hero-sub {
  font-size: 17px;
  font-weight: 400;
  color: #aaa;
  letter-spacing: 0;
  margin: 0;
  max-width: 520px;
}

.design-3 .content {
  max-width: 900px;
  margin: 0 auto;
  padding: 48px 40px 56px;
}

.design-3 .content > p {
  margin: 16px 0;
  color: #333;
  max-width: 680px;
}

.design-3 h3 {
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 3px;
  color: #bbb;
  margin-top: 48px;
  margin-bottom: 20px;
  border-bottom: none;
  padding-bottom: 0;
}

.design-3 #refs-index {
  color: #555;
  padding-left: 0;
  padding-right: 0;
}

.design-3 .csl-entry {
  margin: 18px 0;
  font-size: 15px;
  line-height: 1.55;
  color: #555;
  padding-left: 20px;
  border-left: 3px solid #e63946;
}

.design-3 a {
  color: #e63946;
  text-decoration: none;
}

.design-3 a:hover {
  text-decoration: underline;
}

.design-3 .footer {
  margin-top: 52px;
  padding-top: 16px;
  border-top: 1px solid #eee;
  font-size: 13px;
  color: #aaa;
}
```

**Step 3: Verify in browser**

Reload. Design 3 should show: full-width dark hero band with enormous white title, body content in wider column, publications with red accent left-border rules.

---

### Task 5: Final polish and commit

**Files:**
- Modify: `prototype.html`

**Step 1: Add separator styling between designs**

Add to `<style>` under the reset section:

```css
.proto-label {
  position: sticky;
  top: 0;
  z-index: 10;
}
```

This makes the design labels sticky as you scroll, so you always know which design you're viewing.

**Step 2: Verify full prototype**

Open `prototype.html` in browser and check:
- All 3 designs render correctly
- No CSS bleed between sections (scoped by `.design-N`)
- Content is identical across all 3
- Labels stay visible while scrolling

**Step 3: Commit**

```bash
cd /Users/mglevin/Library/CloudStorage/Box-Box/mglev1n.github.io/.claude/worktrees/design-prototypes
git add prototype.html
git commit -m "feat: add design prototype with 3 CSS variants"
```

Note: since the worktree directory is gitignored, use `git add -f prototype.html` if needed, or place the file directly in the main repo at `/Users/mglevin/Library/CloudStorage/Box-Box/mglev1n.github.io/prototype.html` and commit from there.

---

## File Placement Note

The worktree at `.claude/worktrees/design-prototypes/` is gitignored. Place `prototype.html` in the **main repo root** (`/Users/mglevin/Library/CloudStorage/Box-Box/mglev1n.github.io/prototype.html`) so it can be committed and opened alongside `styles.css` and `index.qmd`.

## After Reviewing Prototypes

Once you've chosen a preferred design (or selected elements from multiple designs), the next step is to update `styles.css` in the main repo to match. The existing `styles.css` is clean and well-organized — targeted edits per the chosen design's CSS rules will be straightforward.
