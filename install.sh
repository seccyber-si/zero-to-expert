#!/usr/bin/env bash
# Installs the zero-to-expert skill and its three agents into Claude Code, by copying files.
# Personal folder ~/.claude by default, or a project's .claude folder with --project. Nothing else is changed.
# Nothing is ever deleted: an existing copy is moved to <.claude>/zero-to-expert-backups/ (with --force or --uninstall).
# Usage: bash install.sh [--project /path/to/repo] [--force] [--uninstall]
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$HOME/.claude"; force=0; uninstall=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project) root="$(cd "$2" && pwd)/.claude"; shift 2 ;;
    --force) force=1; shift ;;
    --uninstall) uninstall=1; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done
skill_dst="$root/skills/zero-to-expert"
agent_dst="$root/agents"
backup="$root/zero-to-expert-backups/$(date +%Y%m%d-%H%M%S)"

exists=0
if [ -e "$skill_dst" ]; then exists=1; fi
for a in "$here"/agents/zero-to-expert-*.md; do
  if [ -e "$agent_dst/$(basename "$a")" ]; then exists=1; fi
done

move_old() {
  if [ -e "$skill_dst" ]; then mkdir -p "$backup"; mv "$skill_dst" "$backup/skill"; fi
  for a in "$here"/agents/zero-to-expert-*.md; do
    t="$agent_dst/$(basename "$a")"
    if [ -e "$t" ]; then mkdir -p "$backup/agents"; mv "$t" "$backup/agents/"; fi
  done
  echo "Previous copy moved to $backup"
}

if [ "$uninstall" = 1 ]; then
  if [ "$exists" = 0 ]; then echo "zero-to-expert is not installed in $root."; exit 0; fi
  move_old
  echo "Uninstalled from $root. The files were moved to the backup folder above, not deleted."
  exit 0
fi
if [ "$exists" = 1 ] && [ "$force" = 0 ]; then
  echo "zero-to-expert is already installed in $root. Run again with --force to replace it (the old copy goes to $root/zero-to-expert-backups)." >&2
  exit 1
fi
if [ "$exists" = 1 ]; then move_old; fi

mkdir -p "$root/skills" "$agent_dst"
cp -R "$here/skills/zero-to-expert" "$skill_dst"
cp "$here"/agents/zero-to-expert-*.md "$agent_dst/"
echo "Installed:"
echo "  skill -> $skill_dst"
for a in "$here"/agents/zero-to-expert-*.md; do echo "  agent -> $agent_dst/$(basename "$a")"; done
echo "Claude Code picks up the skill within seconds. If the skill or the agents do not appear, open a new Claude Code session."
