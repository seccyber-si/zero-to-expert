# Security policy

## Supported versions

Only the latest release receives fixes.

| Version | Supported |
|---|---|
| 1.1.x | Yes |
| < 1.1 | No |

## What counts as a security issue

Zero to Expert is a set of instructions, templates and helper scripts that run on your own machine through Claude. Report privately anything that could harm a user, for example:

- a helper script (`.ps1` / `.sh`) that deletes, overwrites or sends files outside the course folder;
- an install script that changes files it should not touch;
- instructions in the skill or agents that could lead Claude to run unsafe commands, follow injected instructions from a web page, or expose local files or secrets.

Bugs in course quality (wrong facts, broken layout, dead links) are not security issues: open a normal [issue](https://github.com/seccyber-si/zero-to-expert/issues/new/choose) for those.

## How to report

Use the private reporting form: [Report a vulnerability](https://github.com/seccyber-si/zero-to-expert/security/advisories/new). Do not open a public issue for a security problem.

Please include the version, your operating system, the exact command or prompt, and what happened. You should get a first answer within 7 days. Once a fix is released, the advisory is published and you are credited if you wish.
