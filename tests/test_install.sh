#!/usr/bin/env bash
# Dry-run test: install.sh --dry-run must print the bootstrap actions and
# mutate nothing under the target CLAUDE_HOME. Also checks --force and
# --with-conflict-bot behavior in dry-run.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail() { echo "FAIL: $1"; echo "--- output ---"; echo "${2:-}"; exit 1; }

# Clean install (no existing CLAUDE_HOME)
OUT="$(CLAUDE_HOME="$TMP/.claude" bash "$ROOT/install.sh" --dry-run 2>&1)"
echo "$OUT" | grep -q 'git clone .*garrytan/gstack' || fail "missing gstack clone action" "$OUT"
echo "$OUT" | grep -q 'plugin install superpowers'   || fail "missing superpowers install action" "$OUT"
echo "$OUT" | grep -qE 'cp -R.*neb-qa'               || fail "missing neb-qa copy action" "$OUT"
[ ! -e "$TMP/.claude/skills/neb-qa" ]                || fail "dry-run mutated CLAUDE_HOME" "$OUT"

# --force re-clones even when gstack is already present, removing the old clone first
mkdir -p "$TMP/.claude/skills/gstack/.git"
OUTF="$(CLAUDE_HOME="$TMP/.claude" bash "$ROOT/install.sh" --force --dry-run 2>&1)"
echo "$OUTF" | grep -q 'git clone .*garrytan/gstack' || fail "--force did not re-clone gstack" "$OUTF"
echo "$OUTF" | grep -qE 'rm -rf .*gstack'            || fail "--force did not remove old gstack first" "$OUTF"
[ -d "$TMP/.claude/skills/gstack/.git" ]             || fail "dry-run --force mutated gstack dir" "$OUTF"

# --with-conflict-bot prints the optional bot install info
OUTB="$(CLAUDE_HOME="$TMP/.claude" bash "$ROOT/install.sh" --with-conflict-bot --dry-run 2>&1)"
echo "$OUTB" | grep -q 'qa-conflict-bot' || fail "--with-conflict-bot did not print bot info" "$OUTB"

echo "PASS: install.sh dry-run prints actions, mutates nothing, and honors --force / --with-conflict-bot"
