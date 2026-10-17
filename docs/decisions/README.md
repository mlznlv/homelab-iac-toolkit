# Architecture Decision Records

Architecture Decision Records document durable, cross-cutting decisions that affect repository boundaries, lifecycle ownership, contributor behavior, or public interfaces.

## Convention

- Filenames use a four-digit identifier followed by a concise title.
- Every ADR contains Status, Context, Decision, and Consequences.
- Valid statuses are `Proposed`, `Accepted`, `Rejected`, and `Superseded`.
- Proposed ADRs are not authoritative until accepted.
- The decision text of an accepted ADR is immutable.
- A later change is recorded in a new ADR that supersedes the earlier decision.
- Non-semantic corrections may be reviewed without changing the decision.
- ADRs do not duplicate roadmap sequencing or implementation specifications.

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-public-toolkit-private-deployment-boundary.md) | Public toolkit and private deployment boundary | Accepted |
| [0002](0002-lifecycle-orchestration-ownership.md) | Lifecycle and orchestration ownership | Accepted |
| [0003](0003-development-environment-tool-version-policy.md) | Development environment and tool-version policy | Accepted |
| [0004](0004-local-validation-task-ci-security-boundary.md) | Local validation, Task, and CI security boundary | Accepted |
| [0005](0005-first-reusable-toolkit-slice.md) | Adopt the coordinated OpenTofu VM and Ansible guest-agent first slice | Superseded |
| [0006](0006-guest-agent-channel-at-creation.md) | Adopt the coordinated first slice with the guest-agent channel present from creation | Accepted |
| [0007](0007-single-revision-consumer-contract.md) | Single-revision separate-repository consumer contract | Accepted |
| [0008](0008-first-pre-release-contract.md) | First pre-release contract | Accepted |
| [0009](0009-first-m6-vlan-expansion.md) | Optional access-VLAN tagging as the first M6 expansion | Accepted |
| [0010](0010-first-reusable-lxc-capability.md) | First reusable LXC capability | Superseded by 0015; unchanged capability retained there |
| [0011](0011-multiple-vm-network-attachments.md) | Multiple VM network attachments | Superseded by 0014; unchanged interface retained there |
| [0012](0012-dhcp-primary-attachment-addressing.md) | DHCP addressing for the primary VM attachment | Accepted |
| [0013](0013-static-ipv6-primary-attachment.md) | Static IPv6 for the primary VM attachment | Accepted |
| [0014](0014-additional-attachment-retirement-lifecycle.md) | Constrain additional VM attachment retirement on the pinned provider | Accepted |
| [0015](0015-first-lxc-lifecycle-and-dns-contract.md) | Constrain the first LXC capability to evidenced lifecycle and explicit consumer DNS | Accepted |
| [0016](0016-module-cli-minimum-and-evidence-policy.md) | Separate module CLI compatibility from contributor validation | Accepted |
| [0017](0017-guest-distribution-extension-and-qualification.md) | Qualify guest distributions separately for VM templates, LXC, and Ansible roles | Accepted |
| [0018](0018-isolated-live-validation-path.md) | Collect live Proxmox evidence only through an isolated, operator-run path | Accepted |
| [0019](0019-explicit-vm-dns-search-domain.md) | Require an explicit consumer-owned VM DNS search domain | Accepted |
