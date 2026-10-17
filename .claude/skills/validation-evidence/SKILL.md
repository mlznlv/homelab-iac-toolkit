---
name: validation-evidence
description: Run this repository's checks and turn the real output into the evidence block a pull request body needs. Use before opening or updating a pull request, or whenever a change claims validation passed.
---

# Validation evidence

Follow [Contributing](../../../CONTRIBUTING.md#validate-your-change): stage new
files, run the full check set, inspect failures, and report the actual source,
commands, exit results and counts. [Taskfile](../../../Taskfile.yml) owns commands;
[Compatibility](../../../docs/compatibility.md) owns evidence limits.

Never copy counts from an earlier run or present source/mocked checks as live
behavior. Refresh evidence when a push changes checks or their coverage. A
network retry that passes is reported as a retry, with the affected URL; unrelated
failures are reported with evidence rather than silently fixed.
