# A separate consumer repository

This copyable, fictional example composes the [VM
module](../../tofu/modules/proxmox-linux-vm/README.md) and [guest-agent
role](../../ansible/roles/qemu_guest_agent/README.md). It represents a separate repository and
is not deployment-ready. Reusable components do not read it or depend on it.
[Using](../../docs/using.md) owns the consumption contract.

## Layout

| Path | Purpose |
| --- | --- |
| `toolkit-revision.yml` | Full toolkit SHA and represented checkout path |
| `vendor/proxmox-iac-toolkit/` | Checkout you establish; absent from this example |
| `tofu/versions.tf` | Provider declaration; no endpoint, credentials or backend |
| `tofu/main.tf`, `tofu/outputs.tf` | Local module reference and connection output |
| `ansible/ansible.cfg` | Role path into the same checkout |
| `ansible/inventory.yml`, `ansible/guest-agent.yml` | Manual connection mapping and play |
| `tofu/tests/` | Checks inventory matches declared connection values; useful to retain |
| `tests/` | Toolkit's structural example checks; leave behind when copying |

## Getting started

1. Replace the synthetic SHA in `toolkit-revision.yml` with a real full SHA and
   establish that checkout at the recorded path through your own mechanism.
2. Replace every fictional value in the module call and inventory. Choose your
   provider credentials, SSH authentication and backend/state custody using
   [Using](../../docs/using.md#credentials-state-and-secrets) before applying.
3. From this example's `tofu/` directory, initialize and produce a plan:

   ```sh
   tofu init
   tofu plan
   ```

4. Review the plan against the module lifecycle rules, then explicitly run:

   ```sh
   tofu apply
   tofu output connection
   ```

5. Map the returned `host`, `user`, `port` manually into `ansible_host`,
   `ansible_user`, `ansible_port` in `ansible/inventory.yml`.
6. From this example's `ansible/` directory, run:

   ```sh
   ansible-playbook guest-agent.yml
   ```

Run the play where `ansible.cfg` is discoverable (or select it explicitly). Its relative paths
resolve against that file. Checkout path changes must reach both the module source and role
path. Neither the example nor Task acquires the checkout, generates inventory, reads state or
orchestrates deployment.

## Limitations and checks

No backend is declared; the [state warning](../../docs/using.md#credentials-state-and-secrets)
applies before real use. These live invocation steps describe the accepted workflow, not an
executed integration test. [Compatibility](../../docs/compatibility.md#current-evidence-level)
owns evidence limits and [Release policy](../../docs/release-policy.md#maturity) owns
pre-release guarantees.

The repository checks parsing, both paths resolving from a temporary shared checkout, unchanged
inventory mapping, role resolution, the full-SHA declaration and absence of
acquisition/state/secret/orchestration mechanisms. Run the checks through
[Contributing](../../CONTRIBUTING.md#validate-your-change).
