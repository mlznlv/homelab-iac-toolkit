# ADR 0007: Single-revision separate-repository consumer contract

Status: Accepted.

## Decision

- Consume coordinated components from one consumer-owned checkout at one immutable full commit
  SHA recorded exactly in consumer source control.
- Resolve OpenTofu through a local module source and Ansible through ordinary `roles_path`, both
  reaching that checkout.
- Leave acquisition, placement, update/synchronization and credentials to the consumer.
- Represent this arrangement in the public separate-repository example; its vendor-style path is
  a convention, not an interface or acquisition requirement.

## Rationale

Independent remote pins can silently drift. Toolkit-owned fetching would add orchestration
unrelated to either component. Requiring a vendor path or waiting for a release would constrain
consumers without improving exact source selection.

## Consequences

A submodule, provenance-recorded vendoring or another reproducible fetch may satisfy the
contract. Independent references remain component-level alternatives. A SHA selects exact source
without creating stability, migration or support guarantees. [Using](../using.md) owns the
workflow, configuration/secrets and handoff rules; public example validation does not qualify
checkout acquisition or live operation.

## References

- [Consumer workflow](../using.md)
- [Example](../../examples/separate-consumer-repository/README.md)
- [Security](../../SECURITY.md)
