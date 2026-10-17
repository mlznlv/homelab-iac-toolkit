# Using the toolkit

Choose components from the [root index](../README.md#components), check their
interfaces and [compatibility evidence](compatibility.md), then compose them in
your own repository. The [worked example](../examples/separate-consumer-repository/README.md)
shows the coordinated VM and guest-agent workflow.

## One checkout, one commit

Record one immutable **full commit SHA** in your source control, establish one
checkout at that revision, and resolve both components from it: a local OpenTofu
module `source` and Ansible's ordinary `roles_path`. A branch or tag is not the
coordinated pin. Releases state the full SHA in their notes.

Checkout acquisition, location and updates are yours. A submodule, vendored
source with recorded provenance, or another reproducible consumer-owned fetch
can satisfy this contract. `vendor/proxmox-iac-toolkit/` is only the example's
convention. If moved, change the literal module source and `roles_path` together.
Independent remote refs remain possible for component-only use, but are not the
coordinated workflow. [ADR 0007](decisions/0007-single-revision-consumer-contract.md)
explains the single-revision decision.

## What you own

Supply provider configuration, endpoint and runtime credentials; backend and
state custody; templates; node/storage/network identifiers; sizing and addresses;
SSH authentication; inventory; and execution order. The toolkit provides no
acquisition, update, synchronization, discovery or orchestration service.
Component READMEs specify the prerequisites for VLANs, DHCP, IPv6 and templates.

## Workflow

1. Establish the checkout at the recorded SHA.
2. Reference the module and role from that checkout and supply your inputs.
3. Configure provider authentication and choose a backend/state-custody policy.
4. Run `tofu init`, then `tofu plan`; read the plan and lifecycle warnings.
5. Run an explicit `tofu apply` only after human review.
6. Read the non-sensitive `connection` output and map it manually into inventory:

 | Output | Inventory |
 | --- | --- |
 | `host` | `ansible_host` |
 | `user` | `ansible_user` |
 | `port` | `ansible_port` |

7. Run the ordinary Ansible play against that inventory.

The [example](../examples/separate-consumer-repository/README.md#getting-started)
supplies concrete paths. Nothing reads state or generates inventory for you.
Copying the example does not make unattended apply safe.

## Credentials, state, and secrets

Supply endpoints and credentials through native provider/Ansible mechanisms;
see the [provider documentation](https://search.opentofu.org/provider/bpg/proxmox/latest).
They are not module inputs or toolkit authentication interfaces.

The example declares no backend. Applying it creates real infrastructure and
state; without a backend, state is local and may contain sensitive values.
Choose custody **before apply**: the omission is not a local-state recommendation.

The initial workflow commits no encrypted secret document and adds no secret
loader, broker or decryption orchestration. SOPS and age remain the interface
when a supported workflow needs version-controlled ciphertext. Runtime
credentials stay outside Git; [Security](../SECURITY.md#publication-boundary)
defines ciphertext, recipient and private-key handling.

## Upgrading

Review the target revision's [changelog](../CHANGELOG.md), compatibility snapshot
and migration guidance, then update your source-controlled SHA deliberately and
repeat the reviewed-plan workflow. The toolkit migrates no checkout, inventory,
provider constraint, state or configuration. [Release policy](release-policy.md)
defines maturity and immutability; a version label is not a stability guarantee.

## Moving from `homelab-iac-toolkit`

The rename to `proxmox-iac-toolkit` preserved commits and tags; keep your SHA.

- Update a clone with `git remote set-url origin https://github.com/mlznlv/proxmox-iac-toolkit.git`.
- For a submodule, use `git submodule set-url <checkout> https://github.com/mlznlv/proxmox-iac-toolkit.git`
  and commit `.gitmodules`.
- Update remote module source URLs, retain `ref`, and run `tofu init` again when
  it reports `Module source has changed`. Source URLs are not resource addresses;
  this rename requires no state change. Review the plan as usual.
- Keep your existing checkout location or update all path references together.

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `Unreadable module directory` | Establish the checkout; local `source` resolves relative to the declaring module. |
| Role not found; checkout absent from search path | Load `ansible.cfg` from its directory or set `ANSIBLE_CONFIG`. |
| Role not found; checkout present in search path | Verify the checkout exists there. Relative config paths resolve against the config file. |
| Missing/rejected input | Read the named validation rule and component interface; static IPv4 values are conditionally required. |
| Inventory-mapping test fails | Update the manual inventory mapping with the reviewed connection output. |
| `Could not match supplied host pattern` | Match the play's group to inventory; syntax checking can pass while the play runs on no hosts. |
| Components seem to differ in revision | Verify both paths reach one checkout at the recorded SHA; there is no automatic drift detector. |
| Guest agent cannot start | Check the [role prerequisites](../ansible/roles/qemu_guest_agent/README.md#requirements), especially the channel. |

These are structural checks. Runtime provisioning, guest convergence and
reachability need their own diagnosis; [Compatibility](compatibility.md#current-evidence-level)
records the limits of the available evidence.
