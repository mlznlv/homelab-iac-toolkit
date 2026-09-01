# Security

## Project maturity

This project is in its bootstrap, pre-release stage. There is no released
version, no supported-version policy and no compatibility or response-time
commitment. Treat everything here as work in progress.

## What this repository holds

This repository is the public half of a public/private split. It holds reusable
toolkit code, documentation and validation; concrete environment configuration,
credentials and state belong to a separate private deployment repository. The
boundary is defined in
[ADR 0001](docs/decisions/0001-public-toolkit-private-deployment-boundary.md).

Two consequences matter for security:

- Nothing committed here is a secret. No credentials, decryption identities,
  private inventory, generated state or infrastructure identifiers belong in
  this repository, and its checks look for them on every change.
- Validation performs no infrastructure operation. The checks are
  non-destructive, need no credentials, and reach no live environment, so
  running them cannot affect any deployment.

A problem in a deployment built with this toolkit, rather than in the toolkit
itself, belongs with whoever operates that deployment.

## Reporting a problem

**This repository has no private reporting channel at present.** GitHub's
private vulnerability reporting is not enabled here, so anything you send
arrives in public. Open an [issue](https://github.com/mlznlv/homelab-iac-toolkit/issues)
and keep it publishable:

- Do not include credentials, keys, decryption identities, private inventory,
  real hostnames or addresses, or any other sensitive material, whether yours
  or a third party's.
- Describe the problem and how to reproduce it using fictional or
  standards-reserved values, which is what the rest of the repository uses.
- If a report genuinely cannot be written without sensitive material, say that
  in the issue and withhold the material rather than publishing it.

There is no disclosure timeline to promise at this stage. A report will be read
and addressed on the same basis as any other issue.
