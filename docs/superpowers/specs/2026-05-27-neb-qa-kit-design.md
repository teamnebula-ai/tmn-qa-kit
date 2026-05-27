# neb-qa-kit — Design Spec

- **Date:** 2026-05-27
- **Owner:** Shawn Reddy (Team Nebula AI)
- **Repo:** `teamnebula-ai/neb-qa-kit` (public)
- **Status:** Approved design, pre-implementation

## Problem

The NEB team should QA the same way before every merge, but the QA skills Shawn
relies on live in three different places with different installability:

| Skill(s) | Origin | Shareable as files? |
|---|---|---|
| `qa`, `qa-only`, `review`, `design-review`, `devex-review`, `cso`, `investigate`, `browse` | gstack plugin (garrytan/gstack, 3rd-party) | No — their SKILL.md preambles call `~/.claude/skills/gstack/bin/*` and the gstack browse daemon; dead without gstack installed. |
| `verify`, `code-review`, `security-review` | Built into Claude Code | N/A — every teammate already has them in their CC install. |
| `systematic-debugging` | superpowers plugin (3rd-party) | No — lives in the plugin cache, has its own structure. |

Copying these SKILL.md files into a repo would break on teammates' machines
(stale gstack paths), be redundant (built-ins), or redistribute third-party code
(provenance/license concerns).

## Goal

`git clone && ./install.sh` gives any NEB teammate the same QA gate, invoked the
same way, before every merge — without copying or breaking third-party skills.

Non-goals: replacing the upstream skills, vendoring third-party code, or enforcing
QA via CI/git hooks (the gate is harness-driven and advisory-by-convention).

## Approach

The kit ships only what NEB owns and bootstraps everything else from source:

1. **`install.sh`** — installs the upstream plugins, copies the one first-party
   skill into the harness, prints next steps. Idempotent and re-runnable.
2. **`skills/neb-qa/SKILL.md`** — a first-party orchestrator skill (NEB IP) that
   runs the whole gate in order and emits a ship-readiness verdict. It *references*
   upstream skills by name; it does not copy them.
3. **`templates/CLAUDE.qa-gate.md`** — a snippet teammates append to their project
   CLAUDE.md so Claude proactively runs `/neb-qa` before any PR/ship.

## Architecture

```
                        neb-qa-kit (public, teamnebula-ai)
                                     │
            ┌────────────────────────┼─────────────────────────┐
            ▼                        ▼                          ▼
      install.sh              skills/neb-qa/SKILL.md     templates/CLAUDE.qa-gate.md
   (bootstrap, idempotent)    (FIRST-PARTY, our IP)      (snippet → project CLAUDE.md)
            │                        │                              │
            │ installs from source   │ orchestrates                ▼
            ▼                        ▼                       makes Claude run
   ┌─────────────────┐   ┌──────────────────────────────┐   /neb-qa before
   │ gstack (upstream)│   │ THE GATE (in order):         │   any PR/ship
   │ superpowers (up.)│   │ 1 code-review + gstack review│
   │ copies neb-qa →  │   │ 2 run project tests          │
   │  ~/.claude/skills│   │ 3 security-review (+cso)     │
   └─────────────────┘   │ 4 verify / gstack qa         │
                          │ 5 SHIP vs FIX-FIRST verdict  │
                          └──────────────────────────────┘
   built-ins (verify, code-review, security-review) ship with Claude Code already
```

## Components

### 1. `install.sh`

Idempotent bootstrap. Steps, each with a clear pass/skip log line:

1. **Preflight:** confirm `claude` CLI is on PATH and `~/.claude/` exists. If not,
   print the Claude Code install link and exit non-zero.
2. **Install gstack** via its official installer (resolve exact command in the
   implementation plan — gstack documents a one-line installer). Skip if
   `~/.claude/skills/gstack/` already present unless `--force`.
3. **Install superpowers** via the Claude Code plugin marketplace
   (`claude plugin marketplace add` + `claude plugin install superpowers`,
   exact invocation resolved in the plan). Skip if already installed.
4. **Copy `skills/neb-qa` → `~/.claude/skills/neb-qa`** (overwrite on re-run so
   updates land).
5. **Next steps:** print how to append `templates/CLAUDE.qa-gate.md` to a project
   CLAUDE.md, and — only if `--with-conflict-bot` is passed — print the
   qa-conflict-bot GitHub App install link.
6. **Degrade gracefully:** if a step fails (e.g. gstack install errors), warn and
   continue so the built-in pieces of the gate still work; never leave a
   half-broken harness.

Flags: `--force` (reinstall upstream plugins), `--with-conflict-bot` (show the
optional bot wiring), `--dry-run` (print actions against a throwaway `HOME`
without mutating the real harness — used by the test).

### 2. `skills/neb-qa/SKILL.md`

The single "NEB way" entrypoint. Invoked as `/neb-qa` (or "run neb qa").

**The gate, in order:**

1. **Diff/static review** — built-in `code-review` (correctness bugs) + gstack
   `review` (SQL safety, LLM trust boundaries, conditional side effects).
2. **Tests** — detect the project's test command (package.json scripts /
   pyproject / Makefile) and run it; capture pass/fail.
3. **Security** — built-in `security-review`; `cso` daily mode if the project
   opts in.
4. **Behavioral verify** — built-in `verify`; gstack `qa` when the change is a
   web app and a URL is available.
5. **Verdict** — emit **SHIP** or **FIX-FIRST** with an evidence summary,
   **gated on zero critical/high findings**.

**Tiers:** Quick (1 + 3 + 2), Standard (+ 4), Exhaustive (+ `design-review` +
`devex-review`).

**Graceful degradation:** if gstack/superpowers are absent, run the built-in
pieces only and clearly report which steps were skipped and why. For root-cause
debugging, hand off to `systematic-debugging` / `investigate` rather than
re-implementing that discipline.

### 3. `templates/CLAUDE.qa-gate.md`

A short, copy-paste block teammates append to their project CLAUDE.md, e.g.:

> Before opening any PR, run `/neb-qa` and resolve all critical/high findings.
> Do not open a PR with a FIX-FIRST verdict. Use the Standard tier by default;
> Exhaustive for UI-facing changes.

This is what makes the gate automatic inside each teammate's harness.

### 4. `docs/what-each-skill-does.md`

One-pager mapping every upstream skill the gate uses, its origin (gstack /
superpowers / Claude Code built-in), and a link. Establishes credit and lets the
team understand the moving parts.

## Repo Layout

```
neb-qa-kit/
├── README.md
├── LICENSE                      # MIT
├── install.sh
├── skills/neb-qa/SKILL.md
├── templates/CLAUDE.qa-gate.md
└── docs/
    ├── what-each-skill-does.md
    └── superpowers/specs/2026-05-27-neb-qa-kit-design.md   # this file
```

## Testing

- **`install.sh`** — a test runs it with `--dry-run` against a throwaway `HOME`,
  asserting it prints the expected plugin-install and copy actions and mutates
  nothing in the real `~/.claude/`.
- **`neb-qa` skill** — prose, so no unit tests; ships with a smoke checklist in
  the skill doc (invoke on a sample repo, confirm each gate step runs or degrades
  with a clear message, confirm a SHIP/FIX-FIRST verdict is emitted).

## Provenance & Safety

- Public repo → **MIT license**.
- README credits **gstack** (garrytan/gstack) and **superpowers**; `install.sh`
  fetches them from their own sources rather than vendoring.
- **No secrets, no roster PII, no internal hostnames** in any file (public repo).
- Commit identity is the GitHub noreply form to avoid leaking real name/hostname.

## Decisions

- **Gate order:** review → tests → security → verify → verdict (approved as-is).
- **qa-conflict-bot:** opt-in only (`--with-conflict-bot` flag + README mention),
  not a core dependency — the kit stays focused on local QA skills.
- **Enforcement:** convention via the CLAUDE.md snippet, not CI/git hooks.

## Follow-up (out of scope for v1)

- After the repo ships, post a product breakdown + repo link to NEB **#engineering**
  in Slack for the team (separate action, not part of the build).
