---
type: operations
title: install.sh — Bootstrap Mechanics
description: Flags, idempotency behavior, and what the dry-run test actually asserts.
tags: [operations, install, bash, testing]
timestamp: 2026-09-02
---

# install.sh — Bootstrap Mechanics

`install.sh` is the only executable in this repo. It has no dependencies
beyond `git`, `bash`, and the `claude` CLI. Steps below reference
[install.sh](../../install.sh) directly; see
[architecture/overview.md](../architecture/overview.md) for how this fits with
the rest of the kit.

## Flags

| Flag | Effect |
|---|---|
| `--dry-run` | Prints every action (`run`/`run_ok` echo the command via `printf '%q'`) without executing it. Used by `tests/test_install.sh`. |
| `--force` | Reinstalls gstack even if `$CLAUDE_HOME/skills/gstack/.git` already exists — removes the old clone first, then re-clones. |
| `--with-conflict-bot` | After the normal steps, prints the qa-conflict-bot GitHub App install link (`https://github.com/Screddyice/qa-conflict-bot`). Informational only — installs nothing. |
| `-h` / `--help` | Prints usage and exits 0. |
| any other arg | Prints `unknown arg: <arg>` to stderr and exits 2. |

`CLAUDE_HOME` (env var, default `$HOME/.claude`) controls where everything
gets installed — this is what lets the dry-run test point at a throwaway
directory instead of a real harness.

## Steps, in order

1. **Preflight** — if `claude` isn't on `PATH`, warn and exit 1 (unless
   `--dry-run`, which just warns and continues so the action list still
   prints).
2. **gstack** — skip with a log line if `$CLAUDE_HOME/skills/gstack/.git`
   exists and `--force` wasn't passed. Otherwise `rm -rf` any existing dir,
   `git clone --single-branch --depth 1` from `garrytan/gstack`, then run its
   own `./setup`.
3. **superpowers** — `claude plugin marketplace add anthropics/claude-plugins-official`
   then `claude plugin install superpowers@claude-plugins-official`, both run
   via `run_ok` (tolerates non-zero exit, e.g. "already added").
4. **neb-qa skill** — always removes any existing
   `$CLAUDE_HOME/skills/neb-qa` first, then `cp -R` from this repo's
   `skills/neb-qa`. This is a clean overwrite (not skip-if-present) so
   re-running `install.sh` picks up skill updates, and avoids nesting a copy
   inside a copy on repeat runs.
5. **Next steps** — prints the two follow-up actions a user still has to do
   by hand: append `templates/CLAUDE.qa-gate.md` to a target project's
   `CLAUDE.md`, and (if `--with-conflict-bot`) the bot link.

## `run` vs `run_ok`

Both echo the command (array-based via `printf '%q'`, not `eval` — safe with
spaces/special characters per commit `48bdd18`) and skip execution under
`--dry-run`. The difference: `run` propagates a failing command's exit code
(the script has `set -euo pipefail`), `run_ok` swallows it with `|| true`.
`run_ok` is used only for the two `claude plugin` calls, since "already
installed" is an expected, non-fatal outcome there.

## Testing

[tests/test_install.sh](../../tests/test_install.sh) runs `install.sh
--dry-run` against a `mktemp -d` `CLAUDE_HOME` and asserts on stdout, without
ever installing anything for real:

- A clean run's output mentions the gstack clone, the superpowers plugin
  install, and a `cp -R ... neb-qa` action — and afterward
  `$TMP/.claude/skills/neb-qa` still does not exist (dry-run truly mutated
  nothing).
- With a fake `$TMP/.claude/skills/gstack/.git` pre-created, `--force
  --dry-run` output still shows a fresh `git clone` *and* an `rm -rf`
  targeting gstack first — and the pre-created `.git` dir is left untouched
  (still a dry run).
- `--with-conflict-bot --dry-run` output mentions `qa-conflict-bot`.

Run it directly:

```bash
bash tests/test_install.sh
```

Expected output on success:
`PASS: install.sh dry-run prints actions, mutates nothing, and honors --force / --with-conflict-bot`
