# Zero to Expert : le formateur expert pour Claude

[English](README.md) · **Français** · licence [MIT](LICENSE) · [journal des versions](CHANGELOG.md)

Un **skill** et **trois agents** standard qui transforment Claude en formateur. Donnez-lui n'importe quel sujet : il en devient l'expert, cherche lui-même les sources officielles sur le web, puis produit un **cours PDF complet, de zéro à expert**.

## Ce que fait le formateur

1. **Il devient l'expert du domaine.** Il étudie le métier, ses normes, ses organismes, son vocabulaire, les erreurs classiques et les réflexes des pros. Il en tire une « fiche expert » qui donne au cours sa voix.
2. **Il conçoit le parcours comme un enseignant universitaire.** Il prévoit des niveaux de 0 à 5 et des objectifs vérifiables par chapitre, avec une progression où chaque chapitre ne s'appuie que sur les précédents.
3. **Il cherche et vérifie les sources lui-même** : PDF officiels, sites de référence, cours universitaires et vidéos YouTube. Il ouvre chaque lien et vérifie titre, date, durée et niveau. Il n'invente jamais une source.
4. **Il rédige en langage simple et détaillé.** Chaque notion suit le même chemin : une analogie de la vie quotidienne (avec sa limite), une définition en une phrase, puis un schéma, un exemple concret, le regard de l'expert et l'erreur fréquente.
5. **Il ajoute des mini-TP** dans chaque chapitre : 5 à 30 minutes, sans risque, avec résultat attendu et aide « si ça bloque ».
6. **Il illustre chaque chapitre** par des schémas et le conclut par une carte mentale (ou une feuille de route). Le cours se termine par une carte mentale globale sur une page paysage.
7. **Il contrôle avant de livrer.** Il regarde les vraies pages, vérifie tous les liens, et fait relire le cours par un agent relecteur indépendant.

## Contenu d'un cours

| Partie | Contenu |
|---|---|
| Couverture | Titre, chiffres clés, public visé, compétences visées, feuille de route du parcours |
| Mode d'emploi | Légende des encadrés et sommaire automatique |
| Chaque chapitre | Barre de progression, objectifs, « pourquoi c'est important », notions (analogie, définition, schéma, exemple, regard d'expert, erreur fréquente, astuce), mini-TP, « à retenir », auto-évaluation, ressources vérifiées, carte mentale du chapitre |
| Fin du cours | Carte mentale globale (page paysage), plan d'apprentissage avec révisions espacées, projet final, certifications et communautés, glossaire, corrigés, index de toutes les sources avec leur date de vérification |

Six types de schémas sont dessinés automatiquement à partir de simples listes : **carte mentale, feuille de route, processus, cycle, couches ou pyramide, frise chronologique**. Chaque chapitre a sa couleur, la même sur la feuille de route et sur la carte mentale finale.

## Contenu du pack

```
zero-to-expert-pack/
├── README.md / README.fr.md         présentation (anglais / français)
├── CHANGELOG.md                     journal des versions
├── docs/images/                     captures des cours d'exemple
├── LICENSE                          licence MIT
├── CITATION.cff                     comment citer le projet
├── install.ps1 / install.sh         installation par copie (Windows / macOS-Linux)
├── tools/make-release.ps1           construit les zips d'une version (mainteneurs)
├── .claude-plugin/
│   ├── plugin.json                  le pack est un plugin Claude Code...
│   └── marketplace.json             ...et sa propre marketplace
├── agents/
│   ├── zero-to-expert-teacher.md    le formateur autonome (fait tout le cours seul)
│   ├── zero-to-expert-sources.md    le chercheur de sources (en parallèle, par chapitre)
│   └── zero-to-expert-reviewer.md   le relecteur indépendant (avant livraison)
└── skills/zero-to-expert/
    ├── SKILL.md                     la méthode en 7 étapes
    ├── references/                  pédagogie, sources, schémas, check-list qualité
    ├── assets/                      gabarit HTML, feuille de style, moteur de schémas
    └── scripts/                     PDF, aperçu des pages, texte des PDF sources, liens, YouTube
```

## Installation

### A. Claude Code, comme plugin (recommandé pour partager)

Dans une session Claude Code :

```
/plugin marketplace add "<chemin du dossier zero-to-expert-pack>"
/plugin install zero-to-expert@zero-to-expert-pack
```

Directement depuis GitHub : `/plugin marketplace add seccyber-si/zero-to-expert`, puis la même commande `/plugin install`. Avec un plugin, les noms prennent un préfixe : `/zero-to-expert:zero-to-expert` et l'agent `zero-to-expert:zero-to-expert-teacher`.

### B. Claude Code, par copie (le plus simple sur un seul poste)

- Windows : `powershell -ExecutionPolicy Bypass -File .\install.ps1`
- macOS / Linux : `bash install.sh`

Le skill est copié dans `~/.claude/skills/zero-to-expert/` et les agents dans `~/.claude/agents/`. Options :
- `-Project <dossier>` / `--project <dossier>` : installer pour un seul projet ;
- `-Force` / `--force` : remplacer une installation existante ;
- `-Uninstall` / `--uninstall` : désinstaller.

Rien n'est jamais supprimé : une ancienne version est déplacée dans `~/.claude/zero-to-expert-backups/`.

Le skill est pris en compte tout de suite. Si les agents n'apparaissent pas, ouvrez une nouvelle session Claude Code.

### C. claude.ai ou Claude Desktop (skill seul)

Téléchargez [`zero-to-expert-skill.zip`](https://github.com/seccyber-si/zero-to-expert/releases/latest/download/zero-to-expert-skill.zip) puis importez-le dans la partie **Skills** des paramètres (la fonction doit être activée pour votre compte). Les agents n'existent que dans Claude Code. Sur claude.ai, Claude fait donc la recherche et la relecture lui-même. Si l'environnement n'a pas de navigateur Chromium, il livre le cours en HTML : il suffit de l'ouvrir dans un navigateur et de l'imprimer en PDF.

### D. Dans un coffre Obsidian

Copiez le dossier `zero-to-expert-pack` dans votre coffre (par exemple `Outils Claude/`). Les fichiers `.md` se lisent comme des notes. Pour activer le formateur dans Claude Code, lancez l'option B depuis ce dossier.

## Utilisation

- `/zero-to-expert la photographie numérique`
- « Fais-moi un parcours de zéro à expert sur Kubernetes, format court. »
- « Je suis admin système et je prépare ISO 27001 : fais-moi une formation complète, appliquée à mon cas. »
- « Utilise l'agent zero-to-expert-teacher pour me préparer un cours sur la comptabilité pendant que je travaille. » L'agent travaille en arrière-plan et rend le chemin du PDF.

Le formateur applique des réglages par défaut :
- **langue** : celle de votre message ;
- **taille** : standard, soit 6 à 8 chapitres (environ 50 à 90 pages). « court » donne 3 chapitres en mise en page compacte (15 à 20 pages), « complet » 9 à 12 chapitres ;
- **sortie** : le PDF sur votre Bureau, avec un dossier `<sujet>-source` qui permet de modifier le cours plus tard.

## Prérequis

- **Accès web** (recherche et lecture de pages) pour les sources.
- **Un navigateur Chromium pour le PDF** : Edge (présent sur Windows), Chrome, Brave ou Chromium.
- **Pour les scripts** : Windows PowerShell 5.1+ (présent sur Windows), ou bash et curl sur macOS/Linux.
- **Facultatif** : l'extension Claude in Chrome, pour naviguer sur YouTube et les sites dynamiques.

## Personnaliser

- **Couleurs** : la palette `PALETTE` en haut de `assets/diagrams.js`.
- **Polices, marges, encadrés** : `assets/course.css`. `<body class="compact">` donne une mise en page plus dense ; c'est la mise en page du format court.
- **Méthode d'enseignement** : `references/pedagogy.md`.
- **Règles de sources** : `references/sources.md`.

## Limites (honnêtes)

- **Testé le 23/11/2026** sous Windows 11, avec Edge 158, PowerShell 5.1 et Claude Code 2.1.302 :
  - les briques : génération du PDF, six types de schémas, page paysage, planches d'aperçu, typographie française, recherche de phrases dans les PDF (OCR de Windows), vérification des liens, recherche YouTube, validation du plugin ;
  - un test de bout en bout : l'agent formateur a produit seul un cours court sur ISO/IEC 27001 (16 pages, 13 schémas, 4 mini-TP, 27 sources ouvertes et vérifiées). Il lui a fallu 56 minutes et environ 190 actions.
  - L'agent relecteur l'a ensuite examiné en 15 minutes. Il n'a trouvé aucun point bloquant, mais 3 erreurs de fond qu'un auditeur aurait vues, dont un corrigé d'exercice faux. Le formateur les a corrigées.
  - Les faiblesses de méthode relevées par les deux agents ont été corrigées dans le kit.
  - Un deuxième test, au format standard : un cours de 87 pages sur les agents IA (8 chapitres, 20 mini-TP, 29 figures, 88 sources). Le relecteur a trouvé 4 erreurs majeures, dont deux sur la sécurité du bac à sable des TP ; le formateur les a corrigées.
  - Ce test a révélé deux défauts, corrigés depuis :
    - un agent de recherche a effacé deux fichiers temporaires qui n'avaient rien à voir avec le cours (nettoyage avec un joker `yt-*`). Les agents ne suppriment plus que ce qu'ils ont créé, par son chemin exact ;
    - un dossier d'aperçus a été créé hors du dossier du cours, car les scripts résolvaient les chemins relatifs depuis le dossier de démarrage de PowerShell et non depuis le dossier courant. Ils suivent maintenant le dossier courant.
- **Non testé** : les scripts `.sh` (macOS/Linux).
- **Durée** : environ 1 h 20 par cours dans les deux tests, relecture et corrections comprises. Le formateur était seul pour le cours court ; pour le cours standard, quatre agents de recherche travaillaient en parallèle. Un cours complet prendra plus longtemps.
- **Sites protégés** : certains sites officiels refusent les visites automatiques (403, page « êtes-vous un humain »). Le formateur ne contourne jamais ces protections. Il cherche le même texte ailleurs (version PDF, autre site officiel, aperçu gratuit d'une norme, copie archivée) ou renonce à la source.
- **YouTube** : la recherche YouTube sans navigateur lit les pages publiques. Elle peut casser si YouTube change son format ; le formateur passe alors par un navigateur ou par la page web.
- **Relecture humaine** : relisez le cours avant de le diffuser, surtout sur les sujets réglementés (santé, droit, finance, sécurité).

## Auteur et licence

Zero to Expert est distribué sous licence MIT. Vous pouvez l'utiliser, le modifier et le partager, à condition de conserver la mention de copyright et le texte de la licence (fichier `LICENSE`). Pour citer le projet, utilisez `CITATION.cff` ; sur GitHub, c'est le bouton « Cite this repository ».

## Publier une nouvelle version (mainteneurs)

1. Mettez le même numéro de version dans `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` et `CITATION.cff`.
2. Construisez les fichiers : `powershell -ExecutionPolicy Bypass -File tools\make-release.ps1`. Le script vérifie les numéros et l'encodage des scripts, puis crée `zero-to-expert-skill.zip` et `dist/zero-to-expert-pack.zip`.
3. Publiez une *release* GitHub `vX.Y.Z` et joignez-y les deux zips. Leurs noms ne changent jamais, donc les liens « dernière version » restent valables.

