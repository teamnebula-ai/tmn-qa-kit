# tmn-qa-kit

Defer to this repo's own README / config for build, test, and run commands.

<!-- team-context-pointer:start -->
## Team Context (shared memory)

This repo's cross-project context + memory live in your workspace's **team-context** store
(`$CLAUDE_CONFIG_DIR`). Load `boundary/RULES.md` → `projects-context/tmn/CONTEXT.md` →
`memory/tmn/`, and persist back with **`/tmn-sync`**. If it isn't set up locally, run
**`/tmn-context`** first. Workspace layout + setup: your team-context `README.md`.
<!-- team-context-pointer:end -->

<!-- nebby:start -->
## Codebase wiki (nebby)

This repository uses **nebby** to keep a generated, source-grounded wiki in `.nebbywiki/`.
A maintainer added it deliberately — it is part of this repo's tooling, not something that
appeared on its own. Source: https://github.com/teamnebula-ai/teamwiki

**Read it first.** Start at `.nebbywiki/quickstart.md` before grepping source or answering
architecture questions. It maps the architecture, APIs, data models, and workflows, and links to
each section. It is compiled from this codebase and cites real files, so it is a faster way in
than scanning — but it is generated text: verify against source before acting on anything
load-bearing, and trust the code over the wiki when they disagree.

**Do not hand-edit it.** Every page under `.nebbywiki/` is rewritten on the next build and your
edits will be lost. To correct the wiki, fix the code and run `nebby build`.

**The other files are nebby's, and are expected:** `config.json` holds its settings,
`nebby.db` is a local run log (gitignored), and a `post-commit` git hook rebuilds the wiki in
the background after a commit. Run `nebby doctor` if the wiki looks out of date.

Full explanation: `.nebbywiki/README.md`. To remove nebby from this repo: `nebby uninstall`.
<!-- nebby:end -->
