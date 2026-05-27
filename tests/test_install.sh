#!/usr/bin/env bash
# Dry-run test: install.sh --dry-run must print the bootstrap actions and
# mutate nothing under the target CLAUDE_HOME.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

OUT="$(CLAUDE_HOME="$TMP/.claude" bash "$ROOT/install.sh" --dry-run 2>&1)"

fail() { echo "FAIL: $1"; echo "--- output ---"; echo "$OUT"; exit 1; }

echo "$OUT" | grep -q 'git clone .*garrytan/gstack' || fail "missing gstack clone action"
echo "$OUT" | grep -q 'plugin install superpowers'   || fail "missing superpowers install action"
echo "$OUT" | grep -q 'neb-qa'                        || fail "missing neb-qa copy action"
[ ! -e "$TMP/.claude/skills/neb-qa" ]                 || fail "dry-run mutated CLAUDE_HOME"

echo "PASS: install.sh --dry-run prints actions and mutates nothing"
