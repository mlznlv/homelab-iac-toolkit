#!/bin/bash
# Runs the consumer example's own tools against a stand-in toolkit checkout.
#
# The example is written the way a separate repository writes one: its OpenTofu
# module source and its Ansible roles_path both point into
# vendor/homelab-iac-toolkit/, a checkout the consumer establishes. That
# directory is deliberately absent from this repository. Establishing it is the
# consumer's job, and an example that carried a submodule, a vendored copy, or
# a fetch script merely so that CI could run would be teaching an acquisition
# mechanism this toolkit does not own.
#
# So the checkout is built here instead, for the length of this check: the
# example is copied into a temporary directory and this repository is linked in
# at the path the example expects. That is the fixture the Architecture allows
# validation to construct. It stands in for a checkout at the revision
# toolkit-revision.yml declares; it is this working tree, not that commit, and
# nothing here verifies otherwise.
#
# Every command is printed before it runs, and each is one a reader can run by
# hand after making that directory themselves. docs/validation.md documents
# them.
#
# What this proves: the example parses, its module call type-checks against the
# module's real interface, its committed inventory is the connection output
# mapped by hand, and its play resolves the role from the same checkout. What
# it does not prove: that any of it has been applied. The provider is never
# configured, no credential is read, no Proxmox endpoint or guest is contacted,
# and nothing is created.
#
# Usage: examples/separate-consumer-repository/tests/check-example.sh
# Requires: tofu, and the ansible-core and ansible-lint declared for this
# repository. Set PYTHON_TOOL_PREFIX to take those from a virtual environment,
# as Taskfile.yml does. Needs network access for the provider install.

set -euo pipefail

toolkit="$(git rev-parse --show-toplevel)"
example="${toolkit}/examples/separate-consumer-repository"

# Resolved here, against this repository, because the Ansible commands below
# run from inside the fixture: a relative prefix such as Task's default
# .venv/bin/ means nothing once this script has changed directory.
prefix="${PYTHON_TOOL_PREFIX:-}"
case "${prefix}" in
  "" | /*) ;;
  *) prefix="${toolkit}/${prefix}" ;;
esac

fixture="$(mktemp -d)"
trap 'rm -rf "${fixture}"' EXIT

# The consumer repository, with this repository linked in where its
# source-controlled revision says its checkout lives.
consumer="${fixture}/consumer"
mkdir -p "${consumer}" "${consumer}/vendor"
cp -R "${example}/." "${consumer}/"
ln -s "${toolkit}" "${consumer}/vendor/homelab-iac-toolkit"

echo "Represented consumer repository: ${consumer}"
echo "  vendor/homelab-iac-toolkit -> ${toolkit}"

run() {
  echo
  echo "\$ $*"
  "$@"
}

# The provider install is read only against the lock the example commits, so a
# provider that no longer matches it fails here rather than being replaced
# silently. There is no backend to configure: the example declares none.
run tofu -chdir="${consumer}/tofu" init -input=false -backend=false -lockfile=readonly
run tofu -chdir="${consumer}/tofu" validate

# The example's own test mocks the provider, so it contacts nothing and creates
# nothing. It asserts that ansible/inventory.yml is the module's connection
# output mapped into ansible_host, ansible_user and ansible_port unchanged.
run tofu -chdir="${consumer}/tofu" test

# Ansible resolves the relative paths in ansible.cfg against the directory
# holding it, but only finds the file at all when it is the working directory.
cd "${consumer}/ansible"

# Parses the play and resolves the role through roles_path, which reaches the
# same checkout the module came from. Nothing connects to the inventory's host:
# its address is reserved by RFC 5737 and routes nowhere.
run "${prefix}ansible-playbook" --syntax-check guest-agent.yml
run "${prefix}ansible-lint" --offline guest-agent.yml

# Ansible reads the hand-written inventory back, and the three mapped values
# must survive unchanged. This is the same evidence the module's own
# composition check produces, applied to the document a consumer would copy.
run "${prefix}ansible-inventory" --list

"${prefix}ansible-inventory" --list \
  | jq -e '(._meta.hostvars["fictional-vm"] == {ansible_host: "192.0.2.10", ansible_user: "fictional", ansible_port: 22})
      and (.fictional_guests.hosts == ["fictional-vm"])' >/dev/null

echo
echo "The example parses, resolves both components from one checkout, and its inventory reads back unchanged."
