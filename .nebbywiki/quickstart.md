---
type: overview
title: tmn-qa-kit Quickstart
description: What neb-qa-kit is, why it exists, and how its pieces fit together.
tags: [overview, qa, claude-code, skill]
timestamp: 2026-09-02
---

# tmn-qa-kit (neb-qa-kit)

Team Nebula's shared QA gate for Claude Code. One install gives every
teammate the same **review → tests → security → verify** sequence before any
merge, invoked the same way: `/neb-qa`. Source: [README.md](../README.md).

## Why

The team's favorite QA skills live in three places with different
installability:

- [gstack](https://github.com/garrytan/gstack) — third-party plugin (`review`,
  `qa`, `design-review`, `devex-review`, `cso`, `investigate`)
- [superpowers](https://github.com/anthropics/claude-plugins-official) —
  third-party plugin (`systematic-debugging`)
- Claude Code built-ins (`code-review`, `security-review`, `verify`)

You can't just copy those skills' files between machines — gstack's SKILL.md
preambles call `~/.claude/skills/gstack/bin/*` and a browse daemon that don't
exist without gstack installed, and copying built-ins is redundant. So this
repo ships only what Team Nebula owns (one orchestrator skill, a bootstrap
script, a CLAUDE.md snippet, docs) and bootstraps the rest from its own
upstream source at install time. See
[docs/superpowers/specs/2026-05-27-neb-qa-kit-design.md](../docs/superpowers/specs/2026-05-27-neb-qa-kit-design.md)
for the full design rationale.

## The pieces

| Piece | Role |
|---|---|
| [install.sh](operations/install.md) | Idempotent bootstrap: clones gstack, installs the superpowers plugin, copies the `neb-qa` skill into `~/.claude/skills/`. |
| [skills/neb-qa/SKILL.md](workflows/qa-gate.md) | First-party orchestrator skill — the `/neb-qa` gate itself (tiers, steps, verdict). |
| `templates/CLAUDE.qa-gate.md` | Snippet teammates append to a project's `CLAUDE.md` so Claude runs `/neb-qa` before every PR. See [architecture/overview.md](architecture/overview.md). |
| `docs/what-each-skill-does.md` | Map of every skill the gate touches, and which of the three sources it comes from. |
| [tests/test_install.sh](operations/install.md#testing) | Dry-run test asserting `install.sh` prints the right actions and mutates nothing. |

## Quickstart (from README.md)

```bash
git clone https://github.com/teamnebula-ai/neb-qa-kit.git
cd neb-qa-kit
./install.sh
cat templates/CLAUDE.qa-gate.md >> /path/to/your/project/CLAUDE.md
```

Now Claude runs `/neb-qa` before opening a PR in that project, and resolves
every Critical/High finding before shipping. See
[workflows/qa-gate.md](workflows/qa-gate.md) for what that command actually
does, and [architecture/overview.md](architecture/overview.md) for how the
pieces above compose.

## Read next

- [architecture/overview.md](architecture/overview.md) — how install.sh, the
  neb-qa skill, and the CLAUDE.md snippet relate; the bootstrap + gate flow.
- [workflows/qa-gate.md](workflows/qa-gate.md) — the `/neb-qa` gate: tiers,
  steps, graceful degradation, verdict format.
- [operations/install.md](operations/install.md) — install.sh flags,
  idempotency behavior, and what the dry-run test checks.

## Backlog

- **qa-conflict-bot GitHub App** is opt-in only: `install.sh --with-conflict-bot`
  just prints the install link (https://github.com/Screddyice/qa-conflict-bot);
  nothing in this repo installs or configures it.
- **No CI/git-hook enforcement.** The gate is convention-driven via the
  CLAUDE.md snippet, not enforced by a hook or pipeline — a deliberate
  decision recorded in the design spec's "Decisions" section, not a gap to
  fill silently.
- The design spec's own follow-up item — announcing the repo in Slack
  #engineering — is explicitly out of scope for the codebase itself.
