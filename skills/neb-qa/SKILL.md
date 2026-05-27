---
name: neb-qa
description: |
  Team Nebula's QA gate. Runs the full review → tests → security → verify
  sequence on the current change and emits a SHIP / FIX-FIRST verdict gated on
  zero critical/high findings. Use when asked to "neb qa", "run the qa gate",
  "qa before merge", "is this ready to ship", or before creating any PR.
  Three tiers: Quick, Standard (default), Exhaustive.
allowed-tools:
  - Bash
  - Read
  - Grep
  - Glob
  - Skill
  - AskUserQuestion
---

# NEB QA Gate

The single, consistent QA gate for Team Nebula. Run it before opening any PR.
It orchestrates skills you already have; it does not reimplement them.

## Tier

Default to **Standard**. If the user named a tier, use it. If the change is
purely UI-facing, suggest Exhaustive.

| Tier | Steps run |
|------|-----------|
| Quick | 1 Review, 2 Tests, 3 Security |
| Standard (default) | Quick + 4 Behavioral verify |
| Exhaustive | Standard + 5 Design & DX review |

## Preflight: detect what's installed

```bash
[ -d ~/.claude/skills/gstack ] && echo "gstack: yes" || echo "gstack: NO (gstack steps will be skipped)"
claude plugin list 2>/dev/null | grep -qi superpowers && echo "superpowers: yes" || echo "superpowers: NO (systematic-debugging unavailable)"
```

If an upstream skill is missing, run the built-in pieces anyway and record the
skipped steps in the verdict. Never abort the whole gate because one tool is
absent.

## The gate

Run these in order. After each, record findings as Critical / High / Medium /
Low.

1. **Diff & static review.** Invoke the built-in `code-review` skill (correctness
   bugs), then — if gstack is present — the gstack `review` skill (SQL safety,
   LLM trust boundaries, conditional side effects). Collect findings.

2. **Tests.** Detect and run the project's test command:
   - `package.json` with a `test` script → `npm test` (or `bun test` if `bun.lock` exists)
   - `pyproject.toml` / `pytest.ini` → `pytest -q`
   - `Makefile` with a `test` target → `make test`
   - If none found, note "no test command detected" as a Medium finding.
   A failing test is a Critical finding.

3. **Security.** Invoke the built-in `security-review` skill on the diff. If the
   repo opts into deeper scanning (a `.gstack` dir or explicit user request) and
   gstack is present, also run `cso` in daily mode. Collect findings.

4. **Behavioral verify** (Standard+). Invoke the built-in `verify` skill to
   confirm the change actually does what it should. If the change is a web app
   and a URL is available and gstack is present, run gstack `qa` instead for
   live browser testing.

5. **Design & DX review** (Exhaustive only). If gstack is present, invoke
   `design-review` (visual QA) and `devex-review` (developer-experience audit).

For any root-cause debugging surfaced during the gate, hand off to the
`systematic-debugging` skill (superpowers) or gstack `investigate` rather than
guessing at fixes here.

## Verdict

End with one block:

```
NEB QA — <tier> tier
  Review:   <n critical / n high / n medium / n low>
  Tests:    <pass | FAIL: ...>
  Security: <n critical / n high / ...>
  Verify:   <pass | fail | skipped: reason>
  Skipped:  <steps skipped because a tool was absent>

VERDICT: SHIP  ✅      (only if zero Critical and zero High)
   -or-  FIX-FIRST ⛔   (list every Critical/High to resolve)
```

Do not declare SHIP while any Critical or High finding is open.
