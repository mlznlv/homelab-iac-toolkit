# Agent guidance

This file is optional orientation, not project authority. Start at
[README](README.md); use [documentation ownership](CONTRIBUTING.md#documentation-ownership)
to find the document that decides. Current work/dependencies live in GitHub
Issues/Projects; [ADRs](docs/decisions/README.md) explain durable decisions.

- Read the issue/maintainer authority and dependencies before implementation.
  Raise an unresolved architectural question rather than deciding it in code.
- Keep changes inside the authorized scope; report unrelated findings separately.
- Follow [Contributing](CONTRIBUTING.md) and [Security](SECURITY.md). Inspect actual
  values, not just filenames, and keep optional `.claude/` removable.
- Run documented commands/procedures before claiming they work. For behavior
  changes, use a focused failing regression where useful; for documentation,
  verify links, semantic coverage and relevant repository checks.
- Report fresh evidence and limitations using
  [validation-evidence](.claude/skills/validation-evidence/SKILL.md).

## Optional configuration

[Settings](.claude/settings.json) allow inspection/validation commands and register
[unsafe-write](.claude/hooks/block-unsafe-writes.sh) and
[stop-check](.claude/hooks/check-before-stopping.sh) hooks. Stop checking skips absent
tools/no tracked changes, stands down after blocking, and does not replace full
validation. Personal `.claude/settings.local.json` stays ignored.

Review allow-list edits as permission changes: prefix rules cannot exclude
mutating flags (`markdownlint-cli2`, `zizmor` fixes, `git branch` deletion).
CI cannot undo a pre-authorized local mutation. Use
[open-change](.claude/skills/open-change/SKILL.md) for issue/PR handling and the
[public-safety reviewer](.claude/agents/public-safety-reviewer.md) for scoped review.
