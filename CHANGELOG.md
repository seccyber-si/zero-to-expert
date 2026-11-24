# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [1.1.1] - 2026-11-24

First public release.

### Added

- `zero-to-expert` skill: a 7-step method that builds a complete zero-to-expert course on any subject as a diagram-rich PDF, with an HTML template, stylesheet, a diagram engine (mind map, roadmap, process, cycle, layers/pyramid, timeline) and helper scripts (PDF rendering, page previews, PDF text search, link checking, YouTube search).
- Three Claude Code agents: `zero-to-expert-teacher` (autonomous course builder), `zero-to-expert-sources` (per-chapter source research, parallel) and `zero-to-expert-reviewer` (independent review before delivery).
- Claude Code plugin and marketplace manifests, install scripts for Windows (`install.ps1`) and macOS/Linux (`install.sh`), and `tools/make-release.ps1`.
- Short, standard and complete course formats.
- English and French documentation, example course screenshots, MIT license and `CITATION.cff`.

### Fixed (found during the end-to-end tests of 23/11/2026)

- Agents delete only the files they created, by exact path. A wildcard cleanup had removed two unrelated temporary files.
- Helper scripts resolve relative paths from the current folder, not from the folder PowerShell was started in.
- Methodology gaps reported by the reviewer and teacher agents.

[1.1.1]: https://github.com/seccyber-si/zero-to-expert/releases/tag/v1.1.1
