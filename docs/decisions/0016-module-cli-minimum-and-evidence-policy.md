# ADR 0016: Separate module CLI compatibility from contributor validation

Status: Accepted.

## Decision

- Retain 1.6.0 as the intended consumption minimum for both modules; a fixable VM validation
  defect is a target breach, not an exception or reason to raise it.
- Keep three contracts separate: executable module `required_version`, contributor tool pin for
  full validation, and repository test-runner prerequisites.
- Require fresh credential-free consuming-root checks of final unmodified source at the exact
  minimum, with nullable defaults and focused accepted/rejected cases.
- Record source/CLI/acquisition/provider/lock/inputs/commands, successes, failures and scratch
  edits; patched diagnostics do not qualify unchanged source.
- Retain normal full validation and separately required older-version checks; introduce no
  permanent version matrix or inferred interval-wide compatibility.

## Rationale

The #120 investigation found that the VM's nullable identifier/VLAN guards fail on sampled older
CLIs while a newer contributor-pin baseline passes. Raising the floor would avoid the assigned
correction without establishing full compatibility. Mock syntax requirements likewise say
nothing about a consumer module's minimum or whether the complete test suite works on every
later runner.

## Consequences

[Compatibility](../compatibility.md#opentofu-cli-compatibility-and-evidence) keeps known
failures and sampled results visible;
[Contributing](../../CONTRIBUTING.md#module-consumption-compatibility-evidence) owns the
procedure. A future floor change needs deliberate review, evidence and reconciled
declarations/docs; changing the contributor pin cannot do it implicitly. Evidence qualifies
exercised behavior only, not provider lifecycle, future CLIs or live Proxmox/guest behavior.
Signing remediation is independent.

## References

- [Investigation #120](https://github.com/mlznlv/proxmox-iac-toolkit/issues/120#issuecomment-6233199326)
- [Correction #112](https://github.com/mlznlv/proxmox-iac-toolkit/issues/112)
- [Toolchain policy](0003-development-environment-tool-version-policy.md)
