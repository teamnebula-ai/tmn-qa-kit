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

say()  { echo "$*"; }
run()  { echo "+ $*"; [ "$DRY_RUN" -eq 1 ] || eval "$@"; }

# 1. Preflight
if ! command -v claude >/dev/null 2>&1; then
  say "WARN: 'claude' CLI not found on PATH. Install Claude Code: https://docs.anthropic.com/en/docs/claude-code"
  [ "$DRY_RUN" -eq 1 ] || exit 1
fi

# 2. gstack
if [ -d "$GSTACK_DIR/.git" ] && [ "$FORCE" -eq 0 ]; then
  say "gstack: already installed (use --force to reinstall)"
else
  run "git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git \"$GSTACK_DIR\""
  run "(cd \"$GSTACK_DIR\" && ./setup)"
fi

# 3. superpowers
run "claude plugin marketplace add anthropics/claude-plugins-official"
run "claude plugin install superpowers@claude-plugins-official"

# 4. neb-qa skill
run "mkdir -p \"$CLAUDE_HOME/skills\""
run "cp -R \"$NEBQA_SRC\" \"$NEBQA_DST\""

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
