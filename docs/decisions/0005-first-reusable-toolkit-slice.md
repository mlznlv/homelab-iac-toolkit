# ADR 0005: Adopt the coordinated OpenTofu VM and Ansible guest-agent first slice

## Status

Accepted

## Context

M3 requires the smallest reusable capability that gives a separate consumer real value without private deployment dependencies. The first slice could be OpenTofu-first, Ansible-first, or coordinated, but Architecture must select it before implementation is decomposed.

An OpenTofu-only slice could install the guest agent through cloud-init, but that would put the package and service bootstrap inside infrastructure creation and would not exercise the intended Ansible lifecycle boundary. An Ansible-only role would be independently useful but would not prove the intended infrastructure-to-guest lifecycle boundary. Automatically joining the tools through Task would add inventory, credential, state, and ordering assumptions that belong to consumers.

Normal public validation cannot use private PVE infrastructure or credentials and must not claim live evidence it does not produce.

## Decision

Adopt a coordinated OpenTofu VM capability and Ansible guest-agent capability as the first reusable toolkit slice.

The OpenTofu component manages one full-clone Proxmox Linux VM from a consumer-supplied cloud-init template using `bpg/proxmox`. It uses declared static addressing and bootstrap access values. Provider-side guest-agent integration is optional and disabled by default. It may be enabled only after the consumer guarantees that `qemu-guest-agent` is installed, enabled, and running. Initial bootstrap never depends on agent-reported addressing.

The Ansible component independently installs the `qemu-guest-agent` package and ensures that its systemd service is enabled and running. It consumes ordinary inventory and has no dependency on OpenTofu state or output schema.

OpenTofu bootstrap inputs do not transfer continuing ownership of guest users or SSH configuration. OpenTofu owns PVE VM lifecycle, Ansible owns guest-agent package and service state, and the consumer owns provider and backend configuration, credentials, templates, topology, sizing, inventory, private keys, and orchestration.

The OpenTofu component may expose non-sensitive resource and connection values for consumer composition. Those values do not create a required OpenTofu-to-Ansible integration, and Task does not wire the components together.

Compatibility is explicit rather than floating: the public compatibility contract declares one supported PVE major and a capability-based guest contract. Adopting another PVE major requires compatibility review and validation. It requires a new ADR only if the durable policy or another architectural decision changes.

Public evidence for this slice is credential-free static and contract validation. It must cover the module interface and behavior, Ansible syntax and package/service intent, optional composition without state coupling, and publication safety. It must not be represented as live PVE, cloud-init, SSH, distribution-convergence, or guest-agent integration evidence.

Exact input and output names, exact provider and tool versions, executable provider constraints, and the particular test mechanism are implementation or compatibility declarations. They may change without superseding this ADR when the decision and public contract remain intact.

## Consequences

- M3 begins with one OpenTofu module and one independently usable Ansible role.
- A consumer can use either component alone or compose them without access to a private toolkit dependency.
- The normal path requires consumer-controlled creation, inventory composition, guest configuration, and optional later OpenTofu reconciliation.
- The source template does not need to pre-own guest-agent installation.
- Public CI can provide meaningful contract evidence without credentials while keeping its non-claims explicit.
- Templates, provider configuration, inventory generation, automatic Task wiring, live testing, broader component surfaces, consumer examples, and private deployment concerns remain deferred.

## Alternatives considered

- **OpenTofu-first guest-agent installation:** rejected because cloud-init would own continuing package and service concerns and would not exercise the Ansible lifecycle boundary.
- **Ansible-first guest-agent role only:** rejected as the first slice because it would not demonstrate the coordinated infrastructure and guest-configuration model.
- **Task-orchestrated composition:** rejected because it would prematurely couple consumer credentials, inventory, state, and execution order to the public toolkit.
