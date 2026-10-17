# Roadmap

Near-term direction is to improve confidence in the existing VM, LXC and guest configuration
building blocks before widening the catalog. Current status, dependencies, blockers and
acceptance evidence live in [GitHub
Issues](https://github.com/mlznlv/proxmox-iac-toolkit/issues) and Projects, not this page.
Completed consumer changes belong in the [changelog](../CHANGELOG.md).

## Next priorities

- Implement the accepted explicit VM DNS contract through a focused specification:
  [#121](https://github.com/mlznlv/proxmox-iac-toolkit/issues/121) and
  [ADR 0019](decisions/0019-explicit-vm-dns-search-domain.md).
- Expand Proxmox and Ansible capabilities only from demonstrated reusable
  consumer needs; [#80](https://github.com/mlznlv/proxmox-iac-toolkit/issues/80)
  and [#104](https://github.com/mlznlv/proxmox-iac-toolkit/issues/104) hold their gates.

## Later direction

Build supported compositions before broader integration claims. Live validation requires stable
compositions, a reference environment and accepted isolation Architecture;
[#105](https://github.com/mlznlv/proxmox-iac-toolkit/issues/105) tracks that work. Distribution
claims follow [qualification policy](compatibility.md#guest-distribution-qualification).

Optional ecosystem integrations, including dotfiles, require an explicit consumer choice, no
default/recommended private repository, explicit guest eligibility and no secrets distribution.
Stable-release readiness follows credible compatibility evidence and maintenance capacity; no
1.0 commitment is implied. New platform abstractions, registry publication and deployment
automation need separate approved scope.

Direction is not authorization: applicable prerequisites, accepted Architecture and a focused
specification remain separate gates before implementation.
