# Design 2 Monochrome Variations Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Append three high-contrast monochrome variations of Design 2 (2A, 2B, 2C) to the existing `prototype.html`.

**Architecture:** Each variation is appended as a new `.proto-label` + `.proto-frame` + `.design-2X` block at the bottom of `prototype.html`. CSS is scoped under `.design-2a`, `.design-2b`, `.design-2c` ancestor selectors and added inside the existing `<style>` block. Unique IDs (`refs-index-2a`, `refs-index-2b`, `refs-index-2c`) avoid duplicate-ID issues.

**Tech Stack:** Plain HTML5 + CSS3. No JS, no build step. File: `/Users/mglevin/Library/CloudStorage/Box-Box/mglev1n.github.io/prototype.html`

---

### Task 1: Add Variation 2A — Inverted Research Block

Design 2 with a single dramatic inversion: the research overview card becomes near-black with white text. Everything else matches Design 2 exactly except links are black/underlined instead of blue.

**Files:**
- Modify: `/Users/mglevin/Library/CloudStorage/Box-Box/mglev1n.github.io/prototype.html`

**Step 1: Add 2A CSS inside the `<style>` block**

Locate the closing `</style>` tag and insert this CSS block immediately before it:

```css
/* ── Design 2A: Inverted Research Block ───────── */
.design-2a {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', sans-serif;
  font-size: 16px;
  line-height: 1.65;
  color: #111;
  max-width: 800px;
  margin: 0 auto;
  padding: 56px 32px;
}

.design-2a h1 {
  font-size: 40px;
  font-weight: 800;
  letter-spacing: -1px;
  line-height: 1.1;
  margin-bottom: 8px;
}

.design-2a h2 {
  font-size: 13px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: #999;
  margin-bottom: 40px;
  margin-top: 4px;
}

.design-2a h3 {
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 2.5px;
  color: #111;
  margin-top: 0;
  margin-bottom: 14px;
  border-bottom: none;
  padding-bottom: 0;
}

.design-2a .content > p {
  margin: 14px 0;
  color: #333;
}

/* Inverted: dark background, white text */
.design-2a .research-block {
  background: #111;
  color: #fff;
  border-radius: 10px;
  padding: 28px 32px;
  margin: 28px 0;
}

.design-2a .research-block p {
  color: #e8e8e8;
}

.design-2a .research-block a {
  color: #fff;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.design-2a #refs-index-2a {
  border-top: 3px solid #111;
  padding-top: 20px;
  margin-top: 40px;
}

.design-2a .csl-entry {
  border-left: 2px solid #555;
  padding-left: 16px;
  margin: 16px 0;
  font-size: 14.5px;
  line-height: 1.6;
  color: #555;
}

.design-2a a {
  color: #111;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.design-2a a:hover {
  color: #555;
}

.design-2a .footer {
  margin-top: 52px;
  padding-top: 16px;
  border-top: 1px solid #eee;
  font-size: 13px;
  color: #aaa;
}
```

**Step 2: Add 2A HTML section**

Locate the closing `</body>` tag and insert immediately before it:

```html
  <div class="proto-label">DESIGN 2A — Inverted Research Block</div>
  <div class="proto-frame">
    <div class="design-2a">
      <div class="content">
        <h1>Levin Lab</h1>
        <h2>Cardiovascular genetics research at the University of Pennsylvania</h2>

        <div class="research-block">
          <p>We study the genetic basis of cardiovascular disease using large-scale biobanks and electronic health records.</p>
          <p>Our research characterizes how common and rare genetic variation shapes susceptibility to cardiovascular diseases. We use these discoveries to identify therapeutic targets, develop genetic risk prediction tools, and conduct mechanistic clinical studies to validate findings in humans.</p>
          <p>We work with the <a href="#">Million Veteran Program</a>, <a href="#">Penn Medicine Biobank</a>, and other population-scale cohorts using computational genetics, epidemiologic methods, and clinical/translational approaches.</p>
        </div>

        <h3>Selected Publications</h3>

        <div id="refs-index-2a">
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
    </div>
  </div>
```

**Step 3: Verify in browser**

Open `prototype.html`. Scroll to bottom. Design 2A should show a dark (#111) research card with white text, heavy black rule above publications, darker left borders on publication entries, black underlined links.

---

### Task 2: Add Variation 2B — Weight Contrast + Ruled Sections

No background fills. All contrast from font weight (800 headers vs. 300 body) and thick border rules bounding sections.

**Files:**
- Modify: `/Users/mglevin/Library/CloudStorage/Box-Box/mglev1n.github.io/prototype.html`

**Step 1: Add 2B CSS inside the `<style>` block**

Insert immediately before `</style>`:

```css
/* ── Design 2B: Weight Contrast + Ruled Sections ─ */
.design-2b {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', sans-serif;
  font-size: 16px;
  font-weight: 300;
  line-height: 1.65;
  color: #111;
  max-width: 800px;
  margin: 0 auto;
  padding: 56px 32px;
}

.design-2b h1 {
  font-size: 40px;
  font-weight: 800;
  letter-spacing: -1px;
  line-height: 1.1;
  margin-bottom: 8px;
}

.design-2b h2 {
  font-size: 13px;
  font-weight: 400;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: #999;
  margin-bottom: 40px;
  margin-top: 4px;
}

.design-2b h3 {
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 3px;
  color: #111;
  margin-top: 0;
  margin-bottom: 20px;
  border-bottom: none;
  padding-bottom: 0;
}

.design-2b .content > p {
  margin: 14px 0;
  font-weight: 300;
  color: #333;
}

/* Ruled container — no background, just border rules */
.design-2b .research-ruled {
  border-top: 2px solid #111;
  border-bottom: 2px solid #111;
  padding: 24px 0;
  margin: 28px 0;
}

.design-2b .research-ruled p {
  font-weight: 300;
  color: #333;
  margin: 12px 0;
}

.design-2b .pub-section {
  margin-top: 40px;
  border-top: 2px solid #111;
  padding-top: 20px;
}

.design-2b .csl-entry {
  border-left: 4px solid #111;
  padding-left: 16px;
  margin: 18px 0;
  font-size: 14.5px;
  font-weight: 300;
  line-height: 1.6;
  color: #444;
}

.design-2b a {
  color: #111;
  font-weight: 400;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.design-2b a:hover {
  color: #555;
}

.design-2b .footer {
  margin-top: 52px;
  padding-top: 16px;
  border-top: 1px solid #ddd;
  font-size: 13px;
  font-weight: 300;
  color: #aaa;
}
```

**Step 2: Add 2B HTML section**

Insert immediately before `</body>`:

```html
  <div class="proto-label">DESIGN 2B — Weight Contrast + Ruled Sections</div>
  <div class="proto-frame">
    <div class="design-2b">
      <div class="content">
        <h1>Levin Lab</h1>
        <h2>Cardiovascular genetics research at the University of Pennsylvania</h2>

        <div class="research-ruled">
          <p>We study the genetic basis of cardiovascular disease using large-scale biobanks and electronic health records.</p>
          <p>Our research characterizes how common and rare genetic variation shapes susceptibility to cardiovascular diseases. We use these discoveries to identify therapeutic targets, develop genetic risk prediction tools, and conduct mechanistic clinical studies to validate findings in humans.</p>
          <p>We work with the <a href="#">Million Veteran Program</a>, <a href="#">Penn Medicine Biobank</a>, and other population-scale cohorts using computational genetics, epidemiologic methods, and clinical/translational approaches.</p>
        </div>

        <div class="pub-section">
          <h3>Selected Publications</h3>

          <div id="refs-index-2b">
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
        </div>

        <p><a href="#">View all publications →</a></p>
        <p><a href="#">Contact</a> | <a href="#">GitHub</a></p>

        <div class="footer">Last updated: February 28, 2026</div>
      </div>
    </div>
  </div>
```

**Step 3: Verify in browser**

Reload. Design 2B should show: weight-800 title contrasting against weight-300 body text, research overview bounded only by top/bottom rules (no background), publications with bold 4px left-border rules.

---

### Task 3: Add Variation 2C — Data-Table Publications

Light gray research card (same as original Design 2). Publications get a structured table treatment: black header bar, row-per-entry with bottom borders, no left rules.

**Files:**
- Modify: `/Users/mglevin/Library/CloudStorage/Box-Box/mglev1n.github.io/prototype.html`

**Step 1: Add 2C CSS inside the `<style>` block**

Insert immediately before `</style>`:

```css
/* ── Design 2C: Data-Table Publications ───────── */
.design-2c {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', sans-serif;
  font-size: 16px;
  line-height: 1.65;
  color: #111;
  max-width: 800px;
  margin: 0 auto;
  padding: 56px 32px;
}

.design-2c h1 {
  font-size: 40px;
  font-weight: 800;
  letter-spacing: -1px;
  line-height: 1.1;
  margin-bottom: 8px;
}

.design-2c h2 {
  font-size: 13px;
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 2px;
  color: #999;
  margin-bottom: 40px;
  margin-top: 4px;
}

.design-2c .content > p {
  margin: 14px 0;
  color: #333;
}

.design-2c .research-block {
  background: #f6f6f6;
  border-radius: 10px;
  padding: 28px 32px;
  margin: 28px 0;
}

/* Black header bar replacing h3 */
.design-2c .pub-header {
  background: #111;
  color: #fff;
  padding: 10px 16px;
  margin-top: 40px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 3px;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Inter', sans-serif;
}

.design-2c #refs-index-2c {
  border: 1px solid #ddd;
  border-top: none;
  padding: 0 16px;
  margin-top: 0;
}

/* Row-style entries with bottom border, no left rule */
.design-2c .csl-entry {
  border-bottom: 1px solid #ddd;
  border-left: none;
  padding: 14px 0;
  margin: 0;
  font-size: 14.5px;
  line-height: 1.6;
  color: #555;
}

.design-2c .csl-entry:last-child {
  border-bottom: none;
}

.design-2c a {
  color: #111;
  text-decoration: underline;
  text-underline-offset: 2px;
}

.design-2c a:hover {
  color: #555;
}

.design-2c .footer {
  margin-top: 52px;
  padding-top: 16px;
  border-top: 1px solid #eee;
  font-size: 13px;
  color: #aaa;
}
```

**Step 2: Add 2C HTML section**

Insert immediately before `</body>`:

```html
  <div class="proto-label">DESIGN 2C — Data-Table Publications</div>
  <div class="proto-frame">
    <div class="design-2c">
      <div class="content">
        <h1>Levin Lab</h1>
        <h2>Cardiovascular genetics research at the University of Pennsylvania</h2>

        <div class="research-block">
          <p>We study the genetic basis of cardiovascular disease using large-scale biobanks and electronic health records.</p>
          <p>Our research characterizes how common and rare genetic variation shapes susceptibility to cardiovascular diseases. We use these discoveries to identify therapeutic targets, develop genetic risk prediction tools, and conduct mechanistic clinical studies to validate findings in humans.</p>
          <p>We work with the <a href="#">Million Veteran Program</a>, <a href="#">Penn Medicine Biobank</a>, and other population-scale cohorts using computational genetics, epidemiologic methods, and clinical/translational approaches.</p>
        </div>

        <div class="pub-header">Selected Publications</div>

        <div id="refs-index-2c">
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
    </div>
  </div>
```

**Step 3: Verify in browser**

Reload. Design 2C should show: light gray research card (same as original Design 2), solid black "SELECTED PUBLICATIONS" header bar, publications as borderless rows separated only by thin bottom rules, last entry has no bottom border.

---

### Task 4: Commit

**Step 1: Commit**

```bash
cd /Users/mglevin/Library/CloudStorage/Box-Box/mglev1n.github.io
git add prototype.html
git commit -m "feat: add Design 2 monochrome variations (2A inverted, 2B ruled, 2C data-table)"
```

Expected: commit on main branch with prototype.html modified.
