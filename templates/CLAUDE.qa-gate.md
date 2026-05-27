
## QA gate (neb-qa-kit)

Before opening any PR or shipping, run `/neb-qa` and resolve every
Critical/High finding. Never open a PR while the verdict is FIX-FIRST.

- Default to the **Standard** tier.
- Use **Exhaustive** for UI-facing changes.
- If `/neb-qa` reports a tool as skipped, install it (`neb-qa-kit/install.sh`)
  before relying on the verdict.

Set up: https://github.com/teamnebula-ai/neb-qa-kit
