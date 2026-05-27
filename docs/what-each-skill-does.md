# What each skill in the gate does

The `neb-qa` gate orchestrates skills from three sources. This is the map.

| Skill | Origin | Role in the gate |
|-------|--------|------------------|
| `code-review` | Claude Code (built-in) | Correctness bugs in the diff. |
| `review` | [gstack](https://github.com/garrytan/gstack) | SQL safety, LLM trust boundaries, conditional side effects. |
| `security-review` | Claude Code (built-in) | Vulnerabilities in the diff. |
| `cso` | gstack | Deeper infra/security audit (Exhaustive / opt-in). |
| `verify` | Claude Code (built-in) | Confirms the change actually works. |
| `qa` | gstack | Live browser QA for web apps. |
| `design-review` | gstack | Visual QA (Exhaustive). |
| `devex-review` | gstack | Developer-experience audit (Exhaustive). |
| `systematic-debugging` | [superpowers](https://github.com/anthropics/claude-plugins-official) | Root-cause debugging when the gate surfaces a bug. |
| `investigate` | gstack | Alternative root-cause workflow. |

Built-in skills ship with Claude Code — you already have them. gstack and
superpowers are installed by `neb-qa-kit/install.sh`. The `neb-qa` skill itself
is original Team Nebula work.
