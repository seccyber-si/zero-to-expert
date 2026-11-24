# Pedagogy: how to teach like the best

Contents: 1. The two voices · 2. What makes learning stick · 3. Levels 0-5 · 4. Chapter anatomy ·
5. Simple and detailed writing · 6. Everyday-life analogies · 7. Mini-labs · 8. The expert voice ·
9. End matter · 10. Labels (EN / FR)

## 1. The two voices

- **Practitioner**: real stakes, priorities, trade-offs, "here is what we actually do and why". Comes from the expert brief and the sources, never from invented anecdotes.
- **Teacher**: patient, structured, encouraging, never condescending. Anticipates where the learner will get lost and puts a hand there before they fall.
- Together they sound like: "I have seen this go wrong. Here is how to understand it, so it does not happen to you."
- Speak to the learner directly. In French use "vous" by default. Use "tu" only if the user writes that way and clearly wants that tone.

## 2. What makes learning stick, and where the course applies it

| Principle | Why it works | In the course |
|---|---|---|
| Big picture first | New information needs a place to land | Cover roadmap, chapter objectives, progress bar, chapter mind map |
| Concrete before abstract | The brain hooks new ideas onto known ones | Analogy before definition, example before rule |
| Words + pictures | Two memory traces instead of one | A diagram for every important mechanism |
| Small chunks | Working memory holds about 4 new items at once | One idea per paragraph, notions of 1-2 pages, at most 7 items per list or diagram level |
| Worked example → guided practice → autonomy | Beginners learn from studied examples, advanced learners from problems | Example box, mini-lab with steps, "go further" variant, final project |
| Retrieval practice | Recalling strengthens memory more than rereading | Self-check quiz in every chapter, answers in the appendix |
| Spaced review | We forget fast without reviews | Review dates (day 1, day 7, day 30) in the learning plan |
| Connections | Knowledge is a network, not a list | "Link with chapter N" remarks, a final project that mixes chapters |
| Misconceptions confronted | Wrong mental models survive unless challenged head-on | "Common mistake" boxes |
| Relevance | People learn what they see a use for | "Why it matters" with real stakes |
| Feynman test | If you cannot say it simply, you do not understand it | Every definition fits in one plain sentence |

## 3. Levels 0 → 5

| Level | Name | The learner can… | Typical content | Verbs for objectives |
|---|---|---|---|---|
| 0 | Discovery | say what the field is for and recognise its words | big picture, history, stories, jobs | name, recognise, list |
| 1 | Foundations | explain the core notions in their own words | mental models, vocabulary, first diagrams | explain, describe, compare |
| 2 | Guided practice | apply a method by following instructions | procedures, worked examples, guided labs | apply, use, configure, calculate |
| 3 | Autonomy | do common tasks alone and diagnose common problems | troubleshooting, real cases, semi-guided labs | analyse, diagnose, organise |
| 4 | Mastery | choose between options, design a solution, justify trade-offs | standards, best practices, design, costs and risks | evaluate, design, justify, decide |
| 5 | Expert | handle edge cases, review others, anticipate failure, teach | scale, governance, strategy, recent developments, teaching others | create, critique, audit, teach |

For a standard course of 7 chapters, a good spread is: levels 0-1 in two chapters, level 2 in two, level 3 in one, level 4 in one, level 5 in one.

## 4. Chapter anatomy

| Block | Purpose | Size |
|---|---|---|
| Header + chips | Where am I, how long, what do I need | 1 line |
| Objectives | What I will be able to do. Verb + object + condition, checkable ("Calculate the RPO of a service from its business constraints", not "understand RPO") | 3-5 |
| Why it matters | Make the learner want to know. A sourced real incident, or a realistic situation labelled as an example | 3-6 lines |
| Notion (h3) | Analogy → definition → mechanism (diagram) → concrete example → expert view, mistake or tip | 1-2 pages each, 2-5 per chapter |
| Mini-lab | Do it once with your own hands | 1-3 per chapter |
| Key takeaways | What to remember even if you forget the rest | at most 5 full sentences |
| Self-check | Prove it to yourself: 1 recall question, 1-2 "why…?", 1 scenario ("your colleague says… what do you answer?") | 3-5 questions |
| Resources | Where to go deeper, essential first | 2-5 |
| Chapter mind map | The chapter in one picture. Root = chapter, branches = the notions in order, leaves = 1-3 key points of 2-5 words. Use a roadmap if the chapter is a procedure | 1 figure |

## 5. Simple and detailed: the writing rules

- Average sentence of 20 words or fewer. One idea per sentence, one topic per paragraph (5 lines at most).
- Define every term the first time it appears: **term** in bold, then a plain definition. In a non-English course, add the English term in parentheses when learners will meet it in tools or documentation.
- Spell out acronyms at their first use in every chapter.
- Be concrete: numbers, names, commands, real situations, orders of magnitude.
- Give the "why" behind every rule. A rule without a reason is forgotten, or misapplied.
- Show, then tell: the example first, the general rule after.
- At most one new term per sentence. Active voice. Talk to the learner.
- Detailed means deep, not long: steps, conditions, exceptions, limits, numbers.

Before and after (French):

> Avant : « La déduplication permet une optimisation de l'espace de stockage par l'élimination des blocs redondants. »
>
> Après : « La déduplication évite de stocker deux fois la même chose. Le logiciel découpe chaque fichier en petits blocs. S'il retrouve un bloc qu'il a déjà, il ne le recopie pas : il note seulement « voir le bloc n° 42 ». C'est pourquoi trente sauvegardes d'un même serveur prennent bien moins de place que trente copies complètes. »

## 6. Everyday-life analogies

A good analogy has the same mechanism as the notion, not just the same feel. To build one:

1. State the mechanism: what does what to what, and why.
2. Find a daily-life situation with the same mechanism.
3. Map the parts explicitly ("the backup = the photocopy; the off-site copy = the copy kept at your parents'").
4. Say where it stops working ("Limit of the analogy: …").
5. Then give the real term and the precise definition.

Good places to find them: kitchen and recipes, house and keys, post and parcels, library, bank and safe, car and road, supermarket queues, school and exams, hospital triage, airport security, sport and training, plumbing and water, city traffic, an orchestra.

A few examples, to show the range:

- Network packets → parcels in the post. Each has an address, and routers are sorting centres that only look at the next hop.
- Public and private keys → a padlock anyone can snap shut (public key) that only your key can open (private key).
- Compound interest → a snowball rolling downhill: it grows faster because it is already big.
- Database index → the index at the back of a book.
- Cache → keeping your keys by the door instead of in the cellar.
- Camera exposure → filling a bucket in the rain. Aperture is the width of the opening, shutter speed is how long you leave it out, and ISO is how sensitive the scale is.

Use one analogy per notion, and do not stack them. Drop any analogy that is wrong in a way that matters: an analogy that suggests RAID is a backup would teach a dangerous mistake.

## 7. Mini-labs (TP)

**Rules:**

- 5-30 minutes and one goal.
- Free or common material.
- Safe.
- Numbered steps, one action per step.
- An expected result the learner can observe alone.
- "If you are stuck" with the 1-2 likely causes.
- An optional "go further" variant.

**Autonomy grows through the course:**

- Early chapters: fully guided.
- Middle chapters: some choices are left to the learner ("pick the retention yourself and justify it").
- Late chapters: only a problem statement and success criteria.

**Adapt the type to the field:**

- **Technical or IT**: a local lab (virtual machine, container, emulator, sandbox, free tier with spending alerts). Give the command and the expected output.
- **Science**: an observation or measurement with household objects, or a calculation on given data.
- **Business, management or law**: a case study, filling in a template, a decision table, a short memo.
- **Creative fields** (photo, music, writing, design): an exercise with a constraint, such as "10 photos of the same object at 3 apertures".
- **Physical skills** (sport, cooking, crafts): a drill with repetitions, safety notes and self-assessment criteria.
- **Languages**: dialogues, shadowing, spaced flashcards.

**Safety comes first:**

- Never use production systems, real customer data, real money, real accounts or self-medication.
- For electrical, chemical or physical practice, stay within safe limits, say so, and point to professionals.

## 8. The expert voice

- **Expert view**: what pros check first, a rule of thumb with numbers, the trade-off they weigh, what changed recently, or the question they would ask in a job interview.
- **Common mistake**: state the misconception, why people believe it, what it costs, and the correct model.
- **Pro tip**: a habit, a shortcut or a checklist.
- **Concrete example (case box)**: a worked example with real numbers or commands.

Draw these only from the expert brief and the sources. Never invent a "war story" and present it as real.

## 9. End matter

- **Global mind map**: the root is the subject. Add one branch per chapter, in chapter order so the colours match, each with 2-4 leaves for its big ideas. Place it on a landscape page (`section.annex.wide`).
- **Learning plan**:
  - weeks and hours per week;
  - quiz review dates at day 1, day 7 and day 30;
  - what to do when stuck.
- **Final project**:
  - a realistic task that uses most chapters;
  - its deliverables;
  - 4-6 "expert level reached when…" criteria.
- **Going further**: certifications, communities, news sources, conferences, with official links only.
- **Glossary**: every bold term, with a plain definition and the English term.
- **Answers**: per chapter, each answer with a one-sentence explanation of why.
- **All sources**: numbered, with chapter, publisher, type, date, language, the URL, and the date each was checked.

## 10. Labels (EN / FR)

Translate every label of the template into the course language. For another language, translate the English column naturally.

| English | Français |
|---|---|
| Learning path · From zero to expert | Parcours de formation · De zéro à expert |
| chapters · of work · mini-labs · verified sources | chapitres · de travail · mini-TP · sources vérifiées |
| Level 0 → 5 / from zero to expert | Niveau 0 → 5 / de zéro à expert |
| Who is this for? | Pour qui ? |
| By the end you will be able to… | À la fin, vous saurez… |
| How to use this course · Contents | Mode d'emploi · Sommaire |
| Chapter · Level · Time · Prerequisites | Chapitre · Niveau · Durée · Prérequis |
| Objectives · Why it matters | Objectifs · Pourquoi c'est important |
| Everyday life · Limit of the analogy | Dans la vie de tous les jours · Limite de l'analogie |
| Definition · Concrete example | Définition · Exemple concret |
| Expert view · Common mistake · Pro tip · Safety | Le regard de l'expert · Erreur fréquente · Astuce de pro · Sécurité |
| Mini-lab · Goal · You need · Steps | Mini-TP · Objectif · Matériel · Étapes |
| Expected result · If you are stuck · Go further | Résultat attendu · Si ça bloque · Pour aller plus loin |
| Key takeaways · Self-check · Answers in the appendix | À retenir · Auto-évaluation · Corrigé en annexe |
| Resources for this chapter · Type · Resource · Why this one | Ressources du chapitre · Type · Ressource · Pourquoi celle-ci |
| ESSENTIAL · GO FURTHER | ESSENTIEL · POUR ALLER PLUS LOIN |
| VIDEO · PDF · WEB · BOOK · COURSE · TOOL | VIDÉO · PDF · WEB · LIVRE · COURS · OUTIL |
| Chapter N mind map · Figure | Carte mentale du chapitre N · Figure |
| Synthesis: the mind map of the whole course | Synthèse : la carte mentale du parcours |
| Your learning plan · Week · Review | Votre plan d'apprentissage · Semaine · Révisions |
| Final project · You have reached expert level when… | Projet final · Vous êtes au niveau expert quand… |
| Going further: certifications, communities, news | Pour aller plus loin : certifications, communautés, veille |
| Glossary · Answers to the self-checks · All sources | Glossaire · Corrigés des auto-évaluations · Toutes les sources |
| Version of DD/MM/YYYY · sources checked on | Version du JJ/MM/AAAA · sources vérifiées le |

French typography: the no-break spaces before : ; ! ? % » and after « are added by `diagrams.js` when the page has `<html lang="fr">`, so type ordinary spaces. Dates are written DD/MM/YYYY.
