# Diagrams: markup and rules

`assets/diagrams.js` turns plain HTML lists into SVG diagrams when the page loads. Headless Chromium runs it before printing, so the PDF gets vector diagrams. Text is measured with the real font, so boxes fit their labels.

## 1. Which diagram for what

| You want to show | Use | Typical place |
|---|---|---|
| The course or a chapter as steps to walk | `roadmap` | cover, end of a procedural chapter |
| A notion and its parts, or a whole chapter in one picture | `mindmap` | end of every chapter, global synthesis |
| A process with a direction | `flow` | inside a notion |
| Something that loops (life cycle, PDCA, improvement) | `cycle` | inside a notion |
| Levels, layers, a stack, a pyramid | `layers` | inside a notion |
| History, versions, dates | `timeline` | chapter 1 (history of the field), versions |
| Two options side by side | `.versus` box (plain HTML) | trade-offs |
| A domain picture (network, body, circuit, architecture, map) | inline SVG | where needed |

**Room on the page.** The text area of an A4 portrait page is about 264 mm high. These heights were measured with short labels like the examples in section 3:

| Diagram | Printed height |
|---|---|
| `flow`, one row (2-5 steps) | 20-40 mm |
| `flow`, two rows (6-8 steps) | 45-60 mm |
| `roadmap`, up to 4 steps | about 30 mm |
| `roadmap`, 5-8 steps (two rows) | about 50 mm |
| `timeline`, 5 events | about 35 mm |
| `layers`, 4 levels (stack or pyramid) | 45-55 mm |
| `mindmap`, 4 branches × 3 leaves | about 50 mm |
| `mindmap`, 6 branches × 3 leaves | about 75 mm |
| `cycle`, 4 phases | about 80 mm |
| `cycle`, 6 phases | about 90 mm |

- Add about 10 mm for the caption and the spacing.
- Add more when details wrap onto several lines.
- A figure is never split across pages. If less room is left on the page, the figure moves to the next one.

## 2. Common markup

```html
<figure class="dg TYPE" data-option="...">
  <ol> <li><b>Title</b> short detail</li> ... </ol>
  <figcaption><b>Figure 2.3</b>: what to notice.</figcaption>
</figure>
```

- **Items.** Write each item as `<li><b>Title</b> detail</li>` or `<li>Title — detail</li>`. Keep the title to 1-5 words and the detail to 12 words or fewer.
- **Colours.** Items take palette colours in order: blue, teal, orange, purple, rose, green, amber, cyan, indigo, magenta. Chapter *i* uses colour *i* everywhere: its header, milestone *i* of the cover roadmap and branch *i* of the global mind map. A learner can follow a chapter by its colour.
- **Overriding colours.** `data-colors="#2563eb,#0f766e"` replaces the palette for one figure. Use `#rrggbb` values only. A single colour makes the figure monochrome.
- **Landscape pages.** Inside `<section class="annex wide">`, which is printed in landscape, diagrams get more room.
- **Captions.** Every figure gets a caption that starts with its number in bold, then says what to notice.
- **Errors.** A diagram that fails to draw shows a red frame in the PDF, and the build prints `[diagrams] … failed`.

## 3. Types

### mindmap

```html
<figure class="dg mindmap">
  <ul><li>Centre
    <ul>
      <li>Branch 1<ul><li>Leaf</li><li>Leaf</li></ul></li>
      <li>Branch 2<ul><li>Leaf</li></ul></li>
      <li>Branch 3<ul><li>Leaf</li><li>Leaf</li></ul></li>
    </ul>
  </li></ul>
</figure>
```

- **Layout.**
  - With `auto`, branches go on both sides, clockwise from the top right, when the map has 2 levels or fewer and at least 3 branches.
  - Deeper maps go to the right only.
  - Force a layout with `data-layout="both"` or `data-layout="right"`.
- **Readable on A4 portrait.**
  - Use 3-7 branches and 1-4 leaves per branch.
  - Keep labels to 4 words or fewer.
  - If the map needs more than 3 levels, split it into two maps.
- **Global mind map.**
  - Place it in `<section class="annex wide">` with `data-layout="both"`.
  - Give it one branch per chapter, in chapter order, labelled "1. Title", "2. Title"…
  - Add 2-4 leaves per branch.

### roadmap

```html
<figure class="dg roadmap">
  <ol><li><b>Install the lab</b> 30 min</li><li><b>First backup</b> level 1</li> ... </ol>
</figure>
```

- **Steps.** Use 3-10 steps.
- **Rows.**
  - Up to 4 steps fit on one row.
  - 5-6 steps are laid out 3 per row.
  - 7 or more are laid out 4 per row.
  - `data-per-row="3"` forces the row size.
- **Labels.** The road runs from a "Start" flag to a "Goal" star. These labels follow `<html lang>`.

### flow

```html
<figure class="dg flow"><ol><li><b>Collect</b> logs from agents</li><li><b>Analyse</b> rules and decoders</li><li><b>Alert</b> mail or ticket</li></ol></figure>
```

- **Steps.** Use 2-8 numbered boxes linked by arrows.
- **Rows.** Up to 5 steps fit on one row. Longer flows wrap with an elbow arrow. `data-per-row` sets the row size.

### cycle

```html
<figure class="dg cycle" data-center="PDCA"><ol><li><b>Plan</b></li><li><b>Do</b></li><li><b>Check</b></li><li><b>Act</b></li></ol></figure>
```

- **Phases.** Use 3-8 phases around an ellipse, with arrows between them.
- **Centre.** `data-center` puts a label in the middle.

### layers

```html
<figure class="dg layers" data-shape="pyramid"><ol><li><b>Top</b> detail</li> ... <li><b>Base</b> detail</li></ol></figure>
```

- **Order.** The first item is drawn on top.
- **Shapes.** The default draws equal bands (a stack, for example the OSI layers). `data-shape="pyramid"` makes the last item the widest base.

### timeline

```html
<figure class="dg timeline"><ol><li><b>1991</b> first web page</li><li><b>1995</b> JavaScript</li> ... </ol></figure>
```

- **Events.** Use 3-9 events. Labels alternate above and below the axis.
- **Dates.** Use only sourced dates.

## 4. Custom inline SVG

Use inline SVG when no type fits (architecture, anatomy, circuit, geography…):

```html
<figure>
  <svg viewBox="0 0 680 220" width="680" height="220" font-family="Segoe UI, Arial, sans-serif">
    <defs><marker id="c3-arrow" viewBox="0 0 10 10" refX="8.5" refY="5" markerWidth="8" markerHeight="8"
      markerUnits="userSpaceOnUse" orient="auto"><path d="M0,0 L10,5 L0,10 z" fill="#475569"/></marker></defs>
    <rect x="20" y="60" width="170" height="64" rx="8" fill="#eff6ff" stroke="#2563eb"/>
    <text x="105" y="92" text-anchor="middle" dominant-baseline="central" font-size="12.5" font-weight="700" fill="#1e293b">Client</text>
    <path d="M190,92 L300,92" stroke="#475569" stroke-width="2" fill="none" marker-end="url(#c3-arrow)"/>
    <!-- ... -->
  </svg>
  <figcaption><b>Figure 3.2</b>: ...</figcaption>
</figure>
```

- **Size.**
  - Width is 680 on portrait pages and 980 on landscape pages.
  - Font size is at least 10.5 (about 8 pt printed).
  - Leave at least 8 px between labels.
- **Fitting text.**
  - Leave 8 px of padding inside boxes.
  - For width, count about 6.5 px per character at size 12.
  - Break long labels into several `<text>` lines.
- **Markers and colours.**
  - Marker ids must be unique in the whole document (prefix them with the chapter).
  - Fill with the light tint and stroke with the strong colour.
  - Palette:
    - blue `#2563eb` / tint `#eff6ff`;
    - teal `#0f766e` / tint `#e7f1f0`;
    - orange `#c2410c` / tint `#f9ece6`;
    - purple `#7c3aed` / tint `#f2ebfd`;
    - rose `#be123c` / tint `#f9e7eb`;
    - green `#15803d` / tint `#e8f2ec`;
    - text `#1e293b`;
    - secondary text `#475569`.
- **Legend.** Add a legend whenever a colour or a line style carries meaning.
- **Check the render.** Overlapping labels are the most common defect, so open the page preview.

## 5. Checks

- The build prints `[diagrams] N drawn, 0 failed`.
- It also prints warnings:
  - `[layout] diagram shrunk to 72 %`: the diagram is wider than the page, so its text gets small. Shorten the labels, use `data-layout="right"`, or split the diagram.
  - `[layout] diagram too tall for one page`: use fewer items, or split the diagram in two.
  - `[layout] the cover overflows`: the cover is cut. Shorten the subtitle, the cards or the roadmap labels.
  - `[template] … placeholder(s) left`: some `[placeholders]` were not replaced.
- Open the PNG of every page that holds a diagram. Look for labels that touch, text smaller than the body text by more than a third, and figures cut by a page break.
