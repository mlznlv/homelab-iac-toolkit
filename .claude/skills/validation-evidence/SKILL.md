---
name: validation-evidence
description: Run this repository's checks and turn the real output into the evidence block a pull request body needs. Use before opening or updating a pull request, or whenever a change claims validation passed.
---

# Validation evidence

[`docs/validation.md`](../../../docs/validation.md) is the authority on what each check does and the direct command behind it. This skill does not restate it; it covers the order to work in and the mistakes that have actually cost review rounds here.

## Run it

```sh
task validate
```

For a virtual environment that is not on `PATH`, pass `task validate VENV_BIN=path/to/bin`.

**Stage new files first.** The file-based checks list tracked files, so a file you have created but not staged is invisible to them and passes locally while failing in CI. `git add` before validating, not after.

## Report what it printed

Take every number from the run you just did. Do not carry a count forward from an earlier run, and do not reconstruct one from memory — stale counts have been a blocking review finding here more than once.

A pull request body's Validation section names the checks and their results. The shape, with every count taken from your run:

```text
`task validate` — passed, exit <exit status>.

- Markdown — <n> files, <n> errors
- link validation — <n> links, <n> errors
- consumer example contract check — <n> checks, <n> failures
- OpenTofu module contract tests — <n> passed, <n> failed
- Ansible role contract — <n> checks, <n> failures
- publication-safety patterns — <n> checks, <n> failures
- secret scan — no leaks found
- `git diff --check` — passed
- complete diff reviewed
```

The counts are deliberately not filled in here. A worked example would be a set of numbers to copy, and copying them is the mistake this page exists to prevent — the totals move whenever a check gains a case or the repository gains a file.

Re-run and re-report on **every** push that changes what validation does or how much of it there is, including check counts and the cases a test covers.

## When something fails

**Read which check failed before changing anything.** Three of the fifteen need the public network — the link check and the two that download the declared provider — so a failure there may be upstream rather than yours. Retry once; if it passes, say so plainly and name the URL rather than describing it as green.

A failure in a file this change does not touch is worth stating as such, with the evidence, rather than fixing quietly in the same pull request: unrelated changes are grounds for rejection here.

## What this evidence is not

Every check is credential-free and structural. None of them reaches a Proxmox host or a guest, and none may be described as though it had. [`docs/compatibility.md`](../../../docs/compatibility.md) enumerates what the evidence does and does not demonstrate.
