#!/bin/bash
# Checks that this repository's two publication-safety controls agree.
#
# .gitignore keeps unsafe files out of a commit for every contributor, and
# .claude/hooks/block-unsafe-writes.sh optionally refuses to write them during a
# Claude Code session. Both are expressed as file patterns, so they can drift
# apart silently. This script asserts the intended decision of each control for
# a table of fictional paths: no file is created and no path needs to exist.
#
# A deliberate asymmetry is recorded as such below: generated working data is
# ignored but remains writable, because tools legitimately produce it.
#
# Usage: scripts/check-publication-safety-patterns.sh
# Requires: git, and the jq the hook itself depends on.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

hook=.claude/hooks/block-unsafe-writes.sh

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required: ${hook} depends on it." >&2
  exit 2
fi

checks=0
failures=0

# check <path> <ignored|tracked> <denied|allowed>
check() {
  local path=$1 want_git=$2 want_hook=$3 got_git got_hook status

  if git check-ignore --quiet -- "$path"; then got_git=ignored; else got_git=tracked; fi

  case "$(printf '{"tool_input":{"file_path":"%s"}}' "$path" \
    | "$hook" \
    | jq -r '.hookSpecificOutput.permissionDecision // "allow"')" in
    deny) got_hook=denied ;;
    *) got_hook=allowed ;;
  esac

  checks=$((checks + 1))
  if [ "$got_git" = "$want_git" ] && [ "$got_hook" = "$want_hook" ]; then
    status=ok
  else
    status=FAIL
    failures=$((failures + 1))
  fi

  printf '%-4s %-44s git=%-8s hook=%s\n' "$status" "$path" "$got_git" "$got_hook"
  if [ "$status" = FAIL ]; then
    printf '     expected                                     git=%-8s hook=%s\n' "$want_git" "$want_hook"
  fi
}

echo "Generated state and sensitive plans, which have no public-safe form:"
check "terraform.tfstate"                          ignored denied
check "terraform.tfstate.backup"                   ignored denied
check "terraform.tfstate.example"                  ignored denied
check "fictional-change.tfplan"                    ignored denied
check "fictional-change.tfplan.example"            ignored denied
check "crash.log"                                  ignored denied
check "crash.2026-01-01.log"                       ignored denied

echo
echo "Private inventory, which no placeholder suffix rescues:"
check "inventory/private/hosts.yml"                ignored denied
check "inventories/private/group_vars/all.yml"     ignored denied
check "inventory/private/hosts.yml.example"        ignored denied

echo
echo "Environment and variable files, with their placeholder forms:"
check ".env"                                       ignored denied
check ".env.staging"                               ignored denied
check ".env.sample"                                ignored denied
check ".env.example"                               tracked allowed
check ".env.staging.example"                       tracked allowed
check "fictional.tfvars"                           ignored denied
check "fictional.auto.tfvars"                      ignored denied
check "fictional.tfvars.json"                      ignored denied
check "fictional.tfvars.example"                   tracked allowed
check "fictional.tfvars.json.example"              tracked allowed

echo
echo "Key material and decryption identities:"
check "fictional.key"                              ignored denied
check "fictional.pem"                              ignored denied
check "fictional.pem.example"                      tracked allowed
check "fictional.p12"                              ignored denied
check "fictional.pfx"                              ignored denied
check "fictional.agekey"                           ignored denied
check "fictional.age-key"                          ignored denied
check "key.txt"                                    ignored denied
check "keys.txt"                                   ignored denied
check "key.txt.example"                            tracked allowed
check "id_rsa"                                     ignored denied
check "id_ed25519"                                 ignored denied
check "id_ed25519.pub"                             tracked allowed

echo
echo "Plaintext and decrypted secret material:"
check "fictional.secret"                           ignored denied
check "fictional.secrets"                          ignored denied
check "secrets.yml"                                ignored denied
check "secrets.yaml"                               ignored denied
check "ansible/group_vars/secrets.yml"             ignored denied
check "ansible/host_vars/secrets.yml"              ignored denied
check "secrets.yml.example"                        tracked allowed
check "vault.decrypted"                            ignored denied
check "vault.decrypted.yml"                        ignored denied
check "vault.decrypted.example"                    ignored denied

echo
echo "Reusable public source, which both controls must leave alone:"
check "README.md"                                  tracked allowed
check ".tool-versions"                             tracked allowed
check "tofu/fictional/main.tf"                     tracked allowed
check "ansible/roles/fictional/tasks/main.yml"     tracked allowed
check ".terraform.lock.hcl"                        tracked allowed
check "ansible/group_vars/secrets.sops.yml"        tracked allowed

echo
echo "Working data: ignored, but tools legitimately write it."
check ".terraform/providers/fictional.json"        ignored allowed
check ".task/checksum/fictional"                   ignored allowed
check ".ansible/tmp/fictional"                     ignored allowed
check "fictional.retry"                            ignored allowed
check ".venv/bin/python"                           ignored allowed
check "__pycache__/fictional.pyc"                  ignored allowed
check ".claude/settings.local.json"                ignored allowed
check ".remember/now.md"                           ignored allowed

echo
if [ "$failures" -eq 0 ]; then
  echo "${checks} checks, 0 failures."
else
  echo "${checks} checks, ${failures} failure(s)." >&2
  exit 1
fi
