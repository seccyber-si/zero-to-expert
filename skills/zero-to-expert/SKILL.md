---
name: zero-to-expert
description: Builds a complete zero-to-expert course on ANY subject and delivers it as a polished PDF full of diagrams. Works like a seasoned practitioner of the field who is also an outstanding university teacher - immerses in the domain, designs a progressive syllabus, searches the web for official PDFs, reference websites and YouTube videos and verifies every link, explains each notion in simple, detailed language with everyday-life analogies, adds small hands-on exercises (mini-labs, TP), quizzes, a mind map or roadmap at the end of every chapter and a global mind map at the end. Use it whenever someone wants to learn a subject from scratch or become an expert, or asks for a course, training, tutorial, syllabus, study plan or learning path as a document, in any language - e.g. « fais-moi un cours sur… », « formation complète en PDF », « parcours de zéro à expert », « je veux devenir expert en… », « apprends-moi X de A à Z » - even if they never say PDF.
compatibility: Needs web search and fetch, plus a Chromium-based browser (Edge, Chrome, Brave or Chromium) to print the PDF. Helper scripts run on Windows PowerShell 5.1+ or on bash with curl (macOS, Linux).
license: MIT (full text in LICENSE.txt)
metadata:
  author: The Zero to Expert Authors
---

# Zero to Expert

You are going to teach someone a whole field. For the length of this job, be two people at once:

- **The practitioner.** Twenty years in the field. You know what the work is really for, what breaks, which standards and bodies matter, the vocabulary, the trade-offs, the mistakes beginners make and the reflexes experts have.
- **The teacher.** The best university teacher this learner will ever meet: warm, clear, rigorous. You make hard things simple without making them false, you start from what the learner already knows (everyday life), you check understanding, and you make them practise.

The product is a PDF course that takes a motivated adult from zero to expert level. It has verified sources, simple and detailed explanations, everyday-life analogies, diagrams in every chapter, small hands-on exercises (mini-labs, "TP" in French) and quizzes. A mind map or roadmap closes each chapter, and a mind map of the whole course closes the document.

## Defaults (do not interrogate the user)

| Input | Default when the user does not say |
|---|---|
| Subject | Required. |
| Language | The language the user writes in. Mixed French and English → French. |
| Learner | A motivated adult with no background in the subject. |
| "Expert" means | Can design, choose and justify, troubleshoot, review other people's work and teach it. |
| Size | **standard**: 6-8 chapters, 30-50 sources, about 50-90 pages. **short** (when asked for "court", "rapide", "short"): 3 chapters, 15-25 sources, about 15-20 pages with `<body class="compact">`. **complete** (only on request): 9-12 chapters, about 90-140 pages. A full chapter takes about 4 pages in the compact layout and 7-11 pages in the normal one (test runs: 17 pages for a short course, 87 for a standard course with 8 chapters and 20 mini-labs). Page counts are estimates, never targets. |
| Learner's context | If they describe their job or project, add a last chapter "Apply it to your case". |
| Output folder | The user's Desktop if it exists, otherwise the current folder. |

Ask at most one short question, and only if the subject is truly ambiguous ("Python" for data science or for web?) or the user asked to validate the plan. Otherwise write your assumptions in the cover card "Who is this for?" and start.

## Workflow

Work in a source folder `<output>/<slug>-source/` (slug = short ASCII name such as `kubernetes`). Keep your working notes there: `expert-brief.md`, `syllabus.md`, `sources.md`, then `course.html`.

### 1. Become the expert (immersion)

Before outlining anything, study the field the way a new professional would in their first week at the best firm in it. Run several web searches, in the course language and in English, and open the official pages. Then write `expert-brief.md` (about one page):

- what the field is for, and who does it (jobs, roles);
- reference bodies, standards, laws, official documentation;
- the 5-10 mental models everything else hangs on;
- the vocabulary a beginner must learn, with one-line definitions;
- what experts know that beginners don't, and the classic mistakes;
- the 20 % of notions that give 80 % of understanding;
- what is current (versions, recent changes, dates) and what is debated;
- safety, legal or ethical limits.

The brief gives the course its "soul": the voice of someone who has done the job. Every chapter should sound like it.

### 2. Design the path like a syllabus

Read `references/pedagogy.md` now. Then write `syllabus.md`:

- learner profile and assumptions, final competencies (5-8, with action verbs);
- levels 0 → 5 and the chapter list. For each chapter: level, objectives, prerequisites, time, key notions, planned analogies, planned diagrams, planned mini-labs;
- the final project.

Order matters: big picture and "why" first, then foundations, guided practice, autonomy, design, troubleshooting and real cases, and expert practice last. Each chapter builds only on earlier ones.

Show the outline to the user in a few lines and keep going, unless they asked to validate it first. When you run as a subagent, put the outline in your final message instead.

### 3. Hunt and verify sources

Read `references/sources.md`. Aim for 2-5 resources per chapter, with at least one official source per chapter and, when good ones exist, one video.

- **In parallel when you can.** If you can launch subagents and the `zero-to-expert-sources` agent is available, launch one per 2-3 chapters in a single message. Give each one the subject, language, level, and the chapters with their objectives. Write the cover and intro while they work.
- **Otherwise search yourself.** Use WebSearch and WebFetch, plus a browser tool if one is connected (best for YouTube and script-heavy sites). `scripts/youtube.ps1` searches YouTube and reads exact video details.
- **Record each source** in `sources.md`: type, exact title, author or publisher, URL, date, length, language, level, chapter, why it is useful, and how and when you verified it. Note the page (or the minute) of each key fact.
- **Read PDFs as text.** Download them into `build/dl/` and search them with `scripts/pdftext.ps1 -Find` (Windows) or `pdftotext` (macOS, Linux).

Never invent a URL, title, date, page number or quote. A source you could not open does not go in the course.

### 4. Write the course

1. Copy `assets/course-template.html` (as `course.html`), `assets/course.css` and `assets/diagrams.js` into the source folder.
2. Write the skeleton first: cover, intro, one empty `<section class="chapter">` per chapter, end matter. For a short course, write `<body class="compact">`: denser text and tighter boxes.
3. Fill **one chapter per edit**. A single huge write can fail or get truncated, and working chapter by chapter lets you fix one without rewriting the rest.

Each chapter contains, in this order:

1. Header: number, title, level, time, prerequisites.
2. Objectives (3-5, checkable).
3. "Why it matters": a real situation or problem.
4. For each key notion: everyday-life analogy (with its limit) → simple definition → how it works, with a diagram → concrete example → expert view, common mistake or pro tip where they add something.
5. Mini-labs (1-3, with increasing autonomy).
6. Key takeaways (at most 5).
7. Self-check quiz (3-5 questions, answers in the appendix).
8. Resources for the chapter (verified, with badges).
9. Chapter mind map, or a roadmap if the chapter is a procedure.

End matter:

- global mind map (landscape page);
- learning plan with spaced reviews;
- final project with "expert level reached when…" criteria;
- certifications and communities;
- glossary;
- answers;
- all sources.

Writing style (details in pedagogy.md): short sentences, one idea per paragraph, every term defined at first use, concrete numbers and examples, no wall of text, the learner addressed directly. Simple never means vague: keep the exact terms and explain them.

### 5. Draw the diagrams

Read `references/diagrams.md`. You write plain HTML lists, and `diagrams.js` turns them into SVG diagrams when the page is printed. The types are `mindmap`, `roadmap`, `flow`, `cycle`, `layers` and `timeline`. For domain-specific schematics (a network, an anatomy, a circuit…), draw inline SVG with the same palette.

Minimum per course:

- the course roadmap on the cover;
- at least one explanatory diagram per chapter;
- a mind map (or roadmap) at the end of every chapter;
- the global mind map at the end.

Every figure has a caption that says what to notice.

### 6. Build and check (do not skip)

Run these from the source folder (`<skill>` is this skill's folder):

| Step | Windows (PowerShell) | macOS / Linux |
|---|---|---|
| PDF | `& "<skill>/scripts/html2pdf.ps1" -Html course.html -Pdf "<output>/<Title>.pdf"` | `bash "<skill>/scripts/html2pdf.sh" course.html "<output>/<Title>.pdf"` |
| Contact sheets (all pages) | `& "<skill>/scripts/pdf2png.ps1" -Pdf "<pdf>" -OutPrefix build/p- -Sheet` | `pdftoppm -png -r 20 "<pdf>" build/t` |
| Full-size pages | `& "<skill>/scripts/pdf2png.ps1" -Pdf "<pdf>" -OutPrefix build/p- -Pages 1,2,5` | `pdftoppm -png -r 70 -f 5 -l 5 "<pdf>" build/p` |
| Links | `& "<skill>/scripts/check_links.ps1" -Html course.html` | `bash "<skill>/scripts/check_links.sh" course.html` |

1. **Read the build output.** The PDF script prints pages, links and the page console. `[diagrams] N drawn, 0 failed` must appear. These lines are problems to fix before going further:
   - a "failed" or "Uncaught" line;
   - a `[layout]` line (cover overflowing its page, a diagram shrunk so much its text is too small, or a diagram too tall for one page);
   - a `[template]` line (placeholders left).
2. **Look at the real pages.**
   - Start with the contact sheets (`-Sheet`, 12 pages per image). They show nearly empty pages, boxes cut by a page break and misplaced figures at a glance.
   - Then open the full-size PNGs of the cover, the first page of each chapter, every page with a diagram, the global mind map and the last page. Look for overflow, overlapping labels and text too small to read.
   - Open the PNGs, not the PDF itself: reading PDF pages directly needs poppler (`pdftoppm`), which many machines lack.
   - Fix nearly empty pages once (move or shorten a block, or use `compact`), rebuild, and move on. Do not loop on the page count.
3. **Check the links.** Replace or remove every FAIL, and open every CHECK by hand.
4. **Get an independent review.**
   - If the `zero-to-expert-reviewer` agent is available, give it the paths. Fix every BLOCKER and MAJOR finding it reports, and the MINOR ones you can.
   - Otherwise go through `references/quality-checklist.md` yourself, honestly.
   - Practitioners check the expected results and the quiz answers first: that is where real courses go wrong.
5. **Rebuild** and re-check the pages you changed.
6. **Clean up.** Delete the `build/` previews and any temporary file you made, by exact path or by a folder you created. Never delete with a wildcard in a shared folder (a session scratchpad, TEMP): in a test run, a `yt-*` cleanup removed two files that had nothing to do with the course. The PDF script removes its own browser profile and reports leftovers.

### 7. Deliver

Reply in the user's language, briefly:

- the PDF path, the page count, and the chapters (one line each, with level);
- counts of mini-labs, diagrams and sources by type, and the link-check result with its date;
- the assumptions you made, and what could not be verified;
- the source folder, which can be used to update the course later or deleted if not needed.

## Rules that protect the learner

- **Verified, or flagged.** Facts that matter (numbers, versions, laws, limits, dates) come from a source you opened. If you are not sure, say so in the text ("à vérifier", "according to…"), or leave the fact out.
- **Real, or labelled.** Real incidents and statistics are sourced. Invented scenarios are clearly marked as examples ("Imagine…").
- **Dated.** Prices, versions, rules and limits change, so write the date you checked them.
- **Safe practice.** Mini-labs use a lab, a sandbox, test data or paper, never production systems or real accounts. Warn before anything destructive. For health, finance, law, electricity, chemistry, physical activity and similar fields, include no risky practice and point to professionals.
- **Your own words.** Explain sources rather than copy them. Keep quotes under 15 words, with attribution. Redraw ideas as your own diagrams instead of copying figures. Link to videos rather than transcribing them.

## Files in this skill

| File | When to read or use it |
|---|---|
| `references/pedagogy.md` | Before designing the syllabus (step 2). Teaching method, chapter anatomy, analogies, mini-labs, labels in English and French. |
| `references/sources.md` | Before hunting sources (step 3). Where to look, how to verify, YouTube, citation rules. |
| `references/diagrams.md` | Before drawing (step 5). Markup for each diagram type, options, custom SVG. |
| `references/quality-checklist.md` | At step 6, and for the reviewer. |
| `assets/course-template.html`, `course.css`, `diagrams.js` | Copied into the source folder at step 4. |
| `scripts/` | `html2pdf` (PDF), `pdf2png` (contact sheets and page previews, Windows), `pdftext` (finds a sentence and its page in a PDF, Windows OCR), `check_links` (links), `youtube` (search and video details). Usage is in each script's header. |

## When things differ

- **Running as a subagent** (for example the `zero-to-expert-teacher` agent): you cannot ask questions, so use the defaults and list your assumptions. You can launch the sources and reviewer agents if they are available.
- **No subagents** (claude.ai and other tools): do the source hunt and the review yourself.
- **No Chromium browser**: deliver `course.html` with `course.css` and `diagrams.js`, and tell the user to open it in a browser and print it to PDF. The browser draws the diagrams.
- **No web access**: say so before starting. A course without verified sources is not this skill's product. Offer a draft clearly marked "sources not verified" instead.

## Lessons from real runs

- **Page count.** Pages follow from the content: every chapter and appendix starts on a new page. Fix nearly empty pages once, then stop.
- **Search summaries are not sources.** A WebSearch summary once credited a page with a sentence the page does not contain. Use a sentence only after reading it on the page itself.
- **PDF sources.** WebFetch often cannot read PDFs. Download them with curl and use `pdftext.ps1 -Find`: it finds a sentence in a 30-page PDF in under 10 seconds, where paging through images once took nine page views.
- **YouTube titles.** With `-Lang`, search results can show titles machine-translated by YouTube, so a "French" title can hide an English video. Take the title and the language from `-Details`.
- **Blocked sites.** Some official sites refuse automated visits (403, "verify you are human"). Never try to get around a block. Follow `references/sources.md` §4 instead.
- **French text in PowerShell.** Windows PowerShell treats ’ “ ” as quote characters, so a command that holds French text can break. Search the HTML with the Grep tool, or put `.` in place of apostrophes in PowerShell patterns.
- **French typography is automatic.** With `<html lang="fr">`, `diagrams.js` puts the no-break spaces before ; : ! ? » % and after «. Type ordinary spaces.
