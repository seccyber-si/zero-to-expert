# Contributing to Zero to Expert

Thanks for your interest. Bug reports, course-quality feedback and pull requests are all welcome.

By taking part you agree to follow the [Code of Conduct](CODE_OF_CONDUCT.md). Security problems go through the [security policy](SECURITY.md), never a public issue.

## Reporting a bug or a weak course

Open an [issue](https://github.com/seccyber-si/zero-to-expert/issues/new/choose) and pick a template. The most useful reports include:

- the version (see `.claude-plugin/plugin.json`) and how you installed it (plugin, `install.ps1` / `install.sh`, or the skill zip on claude.ai);
- your operating system and where you ran it (Claude Code, Claude Desktop, claude.ai);
- the exact request you gave, for example `/zero-to-expert photography, short format`;
- what went wrong: the error message, or the page numbers of the problem in the PDF.

Do not attach courses that contain private or confidential material.

## Proposing a change

1. Fork the repository and create a branch from `main`.
2. Make the change. Keep these project rules:
   - **PowerShell scripts stay pure ASCII.** Windows PowerShell 5.1 reads UTF-8 files without a BOM as ANSI. `tools/make-release.ps1` refuses to build otherwise.
   - **Resolve relative paths** with `$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath(...)`: .NET calls ignore `cd`.
   - **Never delete with a wildcard.** Scripts and agents delete only the files they created, by exact path.
   - **Keep the Windows and macOS/Linux versions in step:** a change to a `.ps1` script usually needs the same change in its `.sh` twin.
   - **No secrets, personal paths or personal data** in the repository.
3. Check your work from the repository root:
   ```
   claude plugin validate .
   powershell -ExecutionPolicy Bypass -File tools\make-release.ps1
   ```
   If you changed the skill or an agent, build a short test course and look at the PDF pages before you open the pull request.
4. Add a line under `## [Unreleased]` in [CHANGELOG.md](CHANGELOG.md).
5. Open a pull request and fill in the template.

## Versioning

The project follows [Semantic Versioning](https://semver.org/). The version number lives in three files that must always match: `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` and `CITATION.cff`. Maintainers bump it when they cut a release.

## License

By contributing, you agree that your contribution is released under the [MIT License](LICENSE).
