# ADR 0007: Single-revision separate-repository consumer contract

## Status

Accepted

## Context

The first reusable slice provides an independently consumable OpenTofu module and Ansible role. M4 must define how a separate repository consumes them together without making either component depend on the other or allowing their revisions to drift silently.

Independent remote Git references could pin each component, but two references can select different toolkit revisions. Toolkit-owned acquisition or synchronization would take control away from the consumer and introduce orchestration unrelated to either component's lifecycle.

This decision operates within the existing [public toolkit and private deployment boundary](0001-public-toolkit-private-deployment-boundary.md), [lifecycle and orchestration ownership](0002-lifecycle-orchestration-ownership.md), [SOPS and age secrets-encryption ownership](../architecture.md#lifecycle-ownership), and [local validation, Task, and CI security boundary](0004-local-validation-task-ci-security-boundary.md).

## Decision

Adopt one consumer-owned toolkit checkout at one immutable full commit SHA as the canonical coordinated separate-repository consumption model.

The consumer's source-controlled material must identify the full commit SHA exactly. Both components consume that same checkout: OpenTofu uses a local module source reaching `tofu/modules/proxmox-linux-vm/`, and Ansible uses an ordinary `roles_path` reaching `ansible/roles/`.

The checkout mechanism and location are not toolkit interfaces. A Git submodule pinned to the full SHA, vendored toolkit content with source and revision provenance recorded in source control, or another consumer-owned fetch mechanism whose immutable full SHA is declared in source control can satisfy the contract.

The toolkit, OpenTofu module, Ansible role, and Task workflow do not acquire, update, synchronize, or choose the checkout. The consumer owns those operations and any credentials they require.

The canonical M4 public example demonstrates this shared-checkout model through local component references. A vendor-style directory may be used as a convention, but its name is not part of the public interface. Independent remote Git pins may remain component-level alternatives, but they are not the canonical coordinated workflow.

## Consequences

- One source-controlled revision determines both component implementations.
- Consumers can choose an acquisition mechanism that fits their repository without transferring its lifecycle to the toolkit.
- The canonical example must represent a separate repository and resolve both components through the same checkout.
- Pinning a full commit SHA provides exact source selection during the pre-release phase without creating M5 release, migration, or compatibility guarantees.
- Configuration, secrets, example content, validation evidence, runtime non-claims, and deferred live testing remain governed by the referenced boundaries and the Architecture documentation rather than becoming additional decisions in this ADR.

## Alternatives considered

- **Independent remote Git references for the module and role:** rejected as the canonical coordinated model because the references can drift independently.
- **Toolkit-owned checkout acquisition or synchronization:** rejected because acquisition belongs to the consumer and is not OpenTofu, Ansible, or Task lifecycle state.
- **A required `vendor/` path or acquisition tool:** rejected because checkout placement and acquisition are consumer implementation choices.
- **Wait for a published release:** rejected because M4 needs reproducible pre-release consumption now; release and semantic-versioning guarantees remain M5 work.
