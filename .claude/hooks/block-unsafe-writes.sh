#!/bin/bash
# Refuses writes to files that must never exist in this public repository.
#
# This repository is the public half of a public/private split: the toolkit is
# published, while concrete environment configuration lives in a separate
# private deployment repository. Secrets, private deployment data and generated
# state are therefore not merely discouraged here, they are out of scope by
# design (see CLAUDE.md and README.md).
#
# The deny list mirrors .gitignore so that the two agree on what "unsafe to
# publish" means; .gitignore keeps such files out of a commit, this hook keeps
# them from being written in the first place.

input=$(cat)
path=$(jq -r '.tool_input.file_path // empty' <<<"$input")
[ -z "$path" ] && exit 0

base=${path##*/}

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

# Templates and examples carry no real values, so they stay writable even when
# their name would otherwise match a pattern below.
case "$base" in
  *.example|*.example.*|*.sample|*.sample.*|*.tpl|*.tmpl) exit 0 ;;
esac

case "$path" in
  */inventory/private/*|*/inventories/private/*|inventory/private/*|inventories/private/*)
    deny "Private inventory data belongs in the private deployment repository, not in this public toolkit (CLAUDE.md: public/private split)." ;;
esac

case "$base" in
  *.tfstate|*.tfstate.*|*.tfplan)
    deny "OpenTofu/Terraform state and plan files are generated state and must never be committed to this public repository (CLAUDE.md: no generated state)." ;;
  .env|.env.*)
    deny "Environment files hold real configuration values. Use a committed .env.example instead (CLAUDE.md: nothing unsafe to publish)." ;;
  *.tfvars|*.tfvars.json|*.auto.tfvars|*.auto.tfvars.json)
    deny "Variable files carry environment-specific values and belong in the private deployment repository. Commit a .tfvars.example instead." ;;
  *.pem|*.key|*.p12|*.pfx|id_rsa|id_dsa|id_ecdsa|id_ed25519|*.agekey|*.age-key)
    deny "Private key material must never be committed. Encrypt secrets with SOPS + age and keep the keys outside this repository." ;;
  *.decrypted|*.decrypted.*|*.secret|*.secrets|secrets.yml|secrets.yaml)
    deny "Decrypted or plaintext secret material must never be committed. Commit only the SOPS-encrypted form." ;;
  crash.log|crash.*.log)
    deny "Crash logs are generated state and can contain environment details; they are excluded from this repository." ;;
esac

exit 0
