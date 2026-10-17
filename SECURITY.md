# Security

## Publication boundary

Everything in this repository and its public artifacts must be safe to publish.
Reusable code, documentation and sanitized examples belong here; concrete
deployments belong to their consumers. [Architecture](docs/architecture.md)
defines that ownership, and [ADR 0001](docs/decisions/0001-public-toolkit-private-deployment-boundary.md)
records why.

Never publish credentials, private keys or decryption identities, real inventory,
private hostnames/addresses/identifiers, topology, generated state, sensitive
plans or logs, or real encrypted secrets and their recipients. Use fictional or
standards-reserved values in examples and reports. `.gitignore`, hooks and
publication/secret checks catch obvious cases; review the content too.

Consumers may commit ciphertext and recipient lists to their own repositories.
Decryption identities stay outside **all** source control, on systems that need
them, distributed through the consumer's private-key process. Keeping a key
beside the ciphertext it opens defeats encryption.

## Validation and releases

Normal validation needs no credentials, private inventory, decryption or live
environment. It performs no infrastructure apply or destroy. Public CI treats
PR code as untrusted; its controls are in [Architecture](docs/architecture.md#validation-boundary).
Release publication uses maintainer authorization outside normal CI under the
[release policy](docs/release-policy.md).

The project provides no response-time or disclosure-timeline commitment at this
stage; see [release maturity](docs/release-policy.md#maturity).
Deployment incidents belong with the deployment's operator.

## Reporting

**There is no private reporting channel currently configured.** Open a public
[issue](https://github.com/mlznlv/proxmox-iac-toolkit/issues) with a description
and reproduction using fictional values. Withhold sensitive material belonging
to you or anyone else. If a report cannot be written safely without it, state
that limitation without publishing the material. Reports are handled through
the ordinary issue process.
