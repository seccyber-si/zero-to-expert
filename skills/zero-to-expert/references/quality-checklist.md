# Quality checklist (before delivery)

Mark each line OK or FIX, with the page or chapter for every FIX.

- The course ships only when no BLOCKER line and no MAJOR line is FIX.
- Fix MINOR lines when you can. List the ones left in the delivery message.

## Blockers

- [ ] The PDF opens with no blank page. No page is less than a quarter full, except the last page of a chapter or section. The page count is not a criterion: never pad or cut content to reach a number.
- [ ] The build printed `[diagrams] N drawn, 0 failed` and no `[layout]` or `[template]` line. Every diagram is readable, no labels overlap, and no figure is cut by a page break.
- [ ] Every chapter has all of these:
  - objectives;
  - at least one everyday-life analogy with its limit;
  - at least one explanatory diagram;
  - at least one mini-lab with an expected result;
  - key takeaways;
  - a self-check;
  - resources;
  - an end-of-chapter mind map or roadmap.
- [ ] The end matter is complete:
  - the cover roadmap;
  - the global mind map on a landscape page;
  - the learning plan;
  - the final project;
  - the glossary;
  - the answers;
  - the source index.
- [ ] The link check shows 0 FAIL, and every CHECK was opened by hand.
- [ ] No source is invented. Every URL in the course is in `sources.md` with a verification note.
- [ ] The mini-labs are safe (lab, sandbox, test data or paper), with a warning before any destructive step. Risky fields point to professionals.
- [ ] One language throughout, with every template label translated and no `[placeholder]` left.

## Major

- [ ] Progression:
  - every chapter uses only notions already defined;
  - levels rise from 0 to 5;
  - the last chapters reach design, troubleshooting and expert practice.
- [ ] Every term is defined at first use (in bold) and appears in the glossary. Acronyms are spelled out at their first use in each chapter. A list of acronyms helps, but it does not replace this.
- [ ] The expected results of the mini-labs and the quiz answers are correct, consistent with the chapter, and graded the way a practitioner would grade them.
- [ ] Every mini-lab can be done with the material it lists. That material is free, or provided in the course. A paid standard or tool is never assumed without a free alternative.
- [ ] Key facts (numbers, versions, limits, laws, dates) are sourced or flagged, and check dates are shown.
- [ ] Each analogy matches the real mechanism and states its limit.
- [ ] Each quiz mixes recall, understanding and a scenario, and every answer explains why.
- [ ] There is at least one official source per chapter. Every video has been checked (title, channel, date, duration).
- [ ] The expert voice is real: field insight, trade-offs and common mistakes, not generic filler or invented anecdotes.

## Minor

- [ ] Sentences are short and paragraphs are 5 lines or fewer. No wall of text.
- [ ] Captions say what to notice, and figure numbers follow each other.
- [ ] The table of contents lists every chapter and appendix in order. Every page except the cover shows its number and the running header.
- [ ] The cover stats match the content (chapters, mini-labs, sources, hours).

## Quick checks

PowerShell:

```powershell
Select-String -Path course.html -Pattern '\[[^\]\r\n]{3,80}\]' | Select-Object -First 20   # leftover [placeholders] (code may give false hits)
(Select-String -Path course.html -Pattern 'class="tp"').Count                            # mini-labs
(Select-String -Path course.html -Pattern 'class="dg ').Count                            # data-driven diagrams
(Select-String -Path course.html -Pattern 'class="analogy"').Count                       # analogies
```

bash:

```bash
grep -o '\[[^]]\{3,80\}\]' course.html | sort -u | head -20
grep -c 'class="tp"' course.html; grep -c 'class="dg ' course.html; grep -c 'class="analogy"' course.html
```
