#!/usr/bin/env bash
# neb-qa-kit bootstrap: install upstream QA plugins + the first-party neb-qa
# skill into the Claude Code harness. Idempotent and re-runnable.
set -euo pipefail

DRY_RUN=0; FORCE=0; WITH_BOT=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --force) FORCE=1 ;;
    --with-conflict-bot) WITH_BOT=1 ;;
    -h|--help)
      echo "Usage: ./install.sh [--dry-run] [--force] [--with-conflict-bot]"
      exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"
GSTACK_DIR="$CLAUDE_HOME/skills/gstack"
SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEBQA_SRC="$SRC_DIR/skills/neb-qa"
NEBQA_DST="$CLAUDE_HOME/skills/neb-qa"

say() { echo "$*"; }

# run: print then execute (skipped under --dry-run). Array-based, no eval — safe with spaces.
run() {
  printf '+'; printf ' %q' "$@"; printf '\n'
  [ "$DRY_RUN" -eq 1 ] || "$@"
}

# run_ok: like run, but tolerates a non-zero exit (idempotent steps that may already be done).
run_ok() {
  printf '+'; printf ' %q' "$@"; printf '\n'
  [ "$DRY_RUN" -eq 1 ] || "$@" || true
}

# 1. Preflight
if ! command -v claude >/dev/null 2>&1; then
  say "WARN: 'claude' CLI not found on PATH. Install Claude Code: https://docs.anthropic.com/en/docs/claude-code"
  [ "$DRY_RUN" -eq 1 ] || exit 1
fi

# 2. gstack (skip if already cloned, unless --force)
if [ -d "$GSTACK_DIR/.git" ] && [ "$FORCE" -eq 0 ]; then
  say "gstack: already installed (use --force to reinstall)"
else
  if [ -d "$GSTACK_DIR" ]; then
    run rm -rf "$GSTACK_DIR"
  fi
  run git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_DIR"
  run bash -c 'cd "$1" && ./setup' _ "$GSTACK_DIR"
fi

# 3. superpowers (idempotent; tolerate "already added/installed")
run_ok claude plugin marketplace add anthropics/claude-plugins-official
run_ok claude plugin install superpowers@claude-plugins-official

# 4. neb-qa skill (overwrite cleanly so updates land; avoid nested copy on re-run)
run mkdir -p "$CLAUDE_HOME/skills"
if [ -d "$NEBQA_DST" ]; then
  run rm -rf "$NEBQA_DST"
fi
run cp -R "$NEBQA_SRC" "$NEBQA_DST"

# 5. Next steps
say ""
say "Done. Next steps:"
say "  1. In each project, append the QA gate to its CLAUDE.md:"
say "       cat templates/CLAUDE.qa-gate.md >> /path/to/project/CLAUDE.md"
say "  2. Run /neb-qa before opening any PR."
if [ "$WITH_BOT" -eq 1 ]; then
  say ""
  say "Optional — qa-conflict-bot GitHub App (auto QA/fix on PRs):"
  say "  https://github.com/Screddyice/qa-conflict-bot"
fi
