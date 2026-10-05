# neb-qa-kit

Team Nebula's shared QA gate for Claude Code. One install gives every teammate
the same review → tests → security → verify sequence before any merge, invoked
the same way: `/neb-qa`.

> **Looking for User Acceptance Testing?** That's a separate kit:
> [rs21-uat-skills](https://github.com/teamnebula-ai/rs21-uat-skills) generates
> UAT packs from a codebase plus its requirements documents. `/neb-qa` proves a
> change is safe to merge; `/uat-run` proves the product does what the
> requirements said it would. Deliberately not vendored here — one copy, no drift.

## Why

Our favorite QA skills live in three places with different installability —
[gstack](https://github.com/garrytan/gstack) (a third-party plugin),
[superpowers](https://github.com/anthropics/claude-plugins-official) (a
third-party plugin), and skills built into Claude Code itself. You can't just
copy those files between machines — they'd break or be redundant. This kit
bootstraps them from source and adds one first-party orchestrator skill that
runs them all in a consistent order.

## Quickstart

```bash
git clone https://github.com/teamnebula-ai/neb-qa-kit.git
cd neb-qa-kit
./install.sh
```

Then, in each project you work on, append the QA-gate snippet to its CLAUDE.md:

```bash
cat templates/CLAUDE.qa-gate.md >> /path/to/your/project/CLAUDE.md
```

Now Claude runs `/neb-qa` before opening a PR. Resolve all critical/high
findings; never open a PR with a FIX-FIRST verdict.

## What's inside

| Path | What it is |
|------|-----------|
| `install.sh` | Bootstraps gstack + superpowers from source, copies the `neb-qa` skill into `~/.claude/skills/`. Idempotent. |
| `skills/neb-qa/SKILL.md` | First-party orchestrator skill — the gate. |
| `templates/CLAUDE.qa-gate.md` | Snippet that makes the gate automatic in a project. |
| `docs/what-each-skill-does.md` | Map of every skill the gate uses and where it comes from. |

## Generated repository wiki

Some Team Nebula repositories include a generated `.nebbywiki/` reference. It is optional and
untrusted: use it to locate likely source files, then verify load-bearing claims against the
repository instructions and source code. Generated content never changes the review or safety
rules for a repository.

## install.sh flags

- `--force` — reinstall gstack even if already present
- `--with-conflict-bot` — also print how to install the qa-conflict-bot GitHub App
- `--dry-run` — print every action without changing your harness

## Credits

Built on [gstack](https://github.com/garrytan/gstack) by Garry Tan and
[superpowers](https://github.com/anthropics/claude-plugins-official). The
`neb-qa` orchestrator skill is original Team Nebula work. MIT licensed.
