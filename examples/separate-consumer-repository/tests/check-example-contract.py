#!/usr/bin/env python3
"""Check that the consumer example still demonstrates the contract it claims to.

The example exists to show one thing: a separate repository consuming both
halves of this toolkit from one checkout pinned at one immutable commit. That
claim is structural, and the tools cannot make it. `tofu validate` proves the
module call type-checks, `tofu test` proves the committed inventory really is
the module's connection output mapped by hand, and `ansible-playbook
--syntax-check` proves the play resolves its role - but all three would keep
passing if the two components were resolved from two different checkouts, if
the pinned revision were a branch name, or if the example quietly grew a fetch
script. This asserts the parts that stay true only because nobody has changed
them.

Four groups of claim are made here:

  the pinned revision is one immutable full commit SHA, declared in source
  control, because an abbreviated SHA, a branch, or a tag would let the two
  components drift apart later even while every check passed today;

  the OpenTofu module source and the Ansible roles_path resolve, as written
  and after path resolution rather than by string comparison, into the same
  represented checkout, which is the whole contract;

  the example owns no acquisition, orchestration, state-reading, generation, or
  secret-handling mechanism - asserted by looking for the artifacts such a
  mechanism leaves behind rather than by grepping prose, so that the README
  stays free to describe a consumer's options in words; and

  every concrete value a reader might copy is fictional or standards-reserved.

It reads files. It contacts no Proxmox endpoint and no guest, holds no
credential, runs nothing, and writes nothing. It is evidence about what the
example declares, never that the example has been applied.

Usage: python3 examples/separate-consumer-repository/tests/check-example-contract.py
Requires: PyYAML, which comes with the declared ansible-core.
"""

import configparser
import ipaddress
import pathlib
import re
import subprocess
import sys

import yaml

EXAMPLE = pathlib.Path(__file__).resolve().parent.parent
EXAMPLES_ROOT = EXAMPLE.parent

REVISION_FILE = EXAMPLE / "toolkit-revision.yml"
TOFU_ROOT = EXAMPLE / "tofu"
ANSIBLE_ROOT = EXAMPLE / "ansible"
MAIN_TF = TOFU_ROOT / "main.tf"
ANSIBLE_CFG = ANSIBLE_ROOT / "ansible.cfg"
INVENTORY = ANSIBLE_ROOT / "inventory.yml"
PLAY = ANSIBLE_ROOT / "guest-agent.yml"

# Where the two components must land inside the represented checkout. These are
# the toolkit's own paths, so they are the same strings this repository lays out.
MODULE_PATH_IN_CHECKOUT = "tofu/modules/proxmox-linux-vm"
ROLES_PATH_IN_CHECKOUT = "ansible/roles"
ROLE = "qemu_guest_agent"

# A full commit SHA and nothing else. Git's abbreviated form, a branch, and a
# tag all resolve differently later, which is exactly what the contract forbids.
FULL_SHA = re.compile(r"^[0-9a-f]{40}$")

# The generated provider lock is excluded from the value scans below: its
# base64 hashes are not values a reader copies, and they trip any pattern loose
# enough to be useful.
GENERATED = {".terraform.lock.hcl"}

# Names that would mean the example had taken on work the contract leaves to the
# consumer, or to no one. Each is an artifact a mechanism leaves behind, not a
# word that might appear in prose: the README is free to tell a reader that a
# submodule is one way to establish the checkout, and must not be able to
# create one.
FORBIDDEN_NAMES = {
    ".gitmodules": "a submodule, which would make the example own checkout acquisition",
    "Taskfile.yml": "Task orchestration, which the contract leaves out of the example",
    "Taskfile.yaml": "Task orchestration, which the contract leaves out of the example",
    "Makefile": "a build or orchestration entry point the example must not own",
    "requirements.yml": "Galaxy acquisition, which is a second way to obtain the role",
    "requirements.yaml": "Galaxy acquisition, which is a second way to obtain the role",
}

# Suffixes that make a file a script whether or not it is marked executable.
SCRIPT_SUFFIXES = {".sh", ".bash", ".zsh", ".ksh", ".py", ".rb", ".pl", ".ps1"}

# Suffixes that would mean state, a plan, or key material had been committed.
FORBIDDEN_SUFFIXES = {
    ".tfstate": "OpenTofu state",
    ".tfplan": "an OpenTofu plan",
    ".pem": "key or certificate material",
    ".key": "key material",
}

# Content that would mean the example reads state, generates inventory, or
# carries a secret, wherever it appears.
FORBIDDEN_CONTENT = {
    "terraform_remote_state": "a remote-state read, which couples the components through state",
    "PRIVATE KEY": "private key material",
    "ANSIBLE_VAULT": "an Ansible Vault payload",
    "$ANSIBLE_VAULT": "an Ansible Vault payload",
    "sops:": "an encrypted secret document, which the initial workflow does not need",
}

# Addresses reserved for documentation by RFC 5737. Every address a reader can
# see must be inside one of them.
DOCUMENTATION_NETWORKS = [
    ipaddress.ip_network("192.0.2.0/24"),
    ipaddress.ip_network("198.51.100.0/24"),
    ipaddress.ip_network("203.0.113.0/24"),
]

IPV4 = re.compile(r"(?<![\w.])(\d{1,3}(?:\.\d{1,3}){3})(?![\w.])")

# Top-level domains reserved so that nothing under them resolves. A name ending
# in one of these is safe whatever precedes it, so a suffix test is the right
# test here.
RESERVED_TLDS = (".invalid", ".example", ".test", ".localhost")

# Named domains the example may reach: the documentation domains from RFC 2606,
# github.com because the example has to say where the toolkit is obtained from,
# and the sites it cites. Anything else is a real place, and a public example
# has no business naming one - least of all a Proxmox endpoint.
#
# These are matched by domain label rather than by string suffix, because a
# suffix test answers the wrong question: "evilgithub.com" ends with
# "github.com" and is a different place owned by somebody else. Only the domain
# itself and names beneath it qualify.
ALLOWED_DOMAINS = (
    "example.com",
    "example.net",
    "example.org",
    "github.com",
    "rfc-editor.org",
    "opentofu.org",
)

# Hosts are looked for where hosts actually appear, rather than by hunting for
# anything dotted: a pattern loose enough to catch a bare hostname also catches
# every `main.tf` and `path.name` in the example and reports nothing useful.
# The two places a real host could reach a reader are a URL and the local part
# of an address, and the inventory's own host entries are checked separately
# against the values they carry.
URL_HOST = re.compile(r"https?://([^/\s\"')]+)")
AT_HOST = re.compile(r"@([a-z0-9](?:[a-z0-9.-]*[a-z0-9])?\.[a-z]{2,})")

checks = 0
failures = 0


def check(description, ok, detail=None):
    global checks, failures
    checks += 1
    if not ok:
        failures += 1
    print(f"{'ok  ' if ok else 'FAIL'} {description}")
    if not ok and detail:
        for line in detail:
            print(f"     {line}")


def tracked(directory):
    """The files git tracks under a directory, in sorted order.

    Tracked rather than walked, for the reason docs/validation.md gives for
    every other file-based check here: a continuous-integration checkout holds
    exactly the tracked files, and a working tree holds more. That difference
    is not theoretical for this example. Following its own README - establish
    the checkout, then `tofu init`, `tofu plan`, `tofu apply` - leaves a
    provider directory, a state file, and possibly a plan in `tofu/`. All three
    are ignored by git and none of them is committed, but a check that walked
    the directory would report them as committed state, read a binary plan as
    text, and print the real addresses out of a real state file while failing.
    """
    listed = subprocess.run(
        ["git", "-C", str(directory), "ls-files", "-z"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout
    return sorted(directory / name for name in listed.split("\0") if name)


def example_files():
    """Every file the example commits."""
    return tracked(EXAMPLE)


def readable_files():
    """The files whose concrete values a reader might copy.

    tests/ is excluded: it is this repository's check of the example rather
    than example content, and it necessarily names the very markers it forbids.
    Nothing is lost by excluding it, because the repository-wide secret scan
    and publication-safety checks read every tracked file including these.
    """
    for path in example_files():
        if path.name in GENERATED or (EXAMPLE / "tests") in path.parents:
            continue
        yield path


def tofu_text():
    """Every OpenTofu file in the example's root, as one document.

    OpenTofu reads the whole directory, so a check that read only main.tf would
    miss a second module block, a backend, or a populated provider block added
    in a file beside it. The mutation cases below cover exactly that.
    """
    return "\n".join(path.read_text() for path in sorted(TOFU_ROOT.glob("*.tf")))


def module_source():
    """Each module block in the example's root, with the source it declares.

    Parsed rather than evaluated because OpenTofu requires a module source to
    be a literal: there is no expression to resolve, and the string in the file
    is the whole of what OpenTofu will use.

    The `source` argument is read from inside its own block rather than from
    the file at large, because `required_providers` uses that same argument
    name for something entirely different. A top-level block ends at the first
    line that is a bare closing brace, which is how `tofu fmt` writes one and
    what the formatting check keeps true.
    """
    text = tofu_text()
    found = []
    for match in re.finditer(r'^module\s+"([^"]+)"\s*\{$', text, re.MULTILINE):
        end = re.compile(r"^\}$", re.MULTILINE).search(text, match.end())
        body = text[match.end() : end.start() if end else len(text)]
        sources = re.findall(r'^\s*source\s*=\s*"([^"]+)"', body, re.MULTILINE)
        found.append((match.group(1), sources))
    return found


def roles_path():
    """The roles_path the example's Ansible configuration declares."""
    parser = configparser.ConfigParser()
    parser.read(ANSIBLE_CFG)
    return parser.get("defaults", "roles_path", fallback=None)


def is_allowed_host(host):
    """Whether a host name is one the example is permitted to reach.

    The comparison is by domain label. `endswith("github.com")` would also
    accept `evilgithub.com`, which is somebody else's domain entirely, so a
    named domain matches only itself and names strictly beneath it.
    """
    host = host.strip().lower().rstrip(".")
    if not host:
        return False
    if host.endswith(RESERVED_TLDS):
        return True
    return any(host == domain or host.endswith(f".{domain}") for domain in ALLOWED_DOMAINS)


def is_documentation_address(text):
    """Whether a dotted-quad is inside one of the RFC 5737 ranges.

    A malformed quad answers no rather than raising. The pattern that finds
    these accepts three digits per octet, so a typo such as 192.0.2.256 reaches
    here; failing the check that asked the question is the useful outcome, and
    an uncaught ValueError partway through the run is not.
    """
    try:
        address = ipaddress.ip_address(text)
    except ValueError:
        return False
    return any(address in network for network in DOCUMENTATION_NETWORKS)


def is_fictional_host(value):
    """Whether a host a reader could try to reach names nothing real.

    Three forms qualify. An address inside one of the RFC 5737 documentation
    ranges is routed nowhere. A name under one of the reserved suffixes above
    resolves nowhere. A bare label carrying no dots is unqualified, so it names
    a host only within a network the reader already owns. Anything else - a
    fully qualified name, or an address outside those ranges - could be a real
    machine, and belongs in a consumer's own repository rather than this one.
    """
    if value is None:
        return True
    value = str(value)
    if re.fullmatch(r"\d{1,3}(?:\.\d{1,3}){3}", value):
        return is_documentation_address(value)
    if is_allowed_host(value):
        return True
    return "." not in value


def resolve(base, declared):
    """Where a relative path in a configuration file actually lands.

    Both paths under test are relative, and comparing them as strings would
    pass a pair that never meets on disk. Resolving each against the directory
    that owns it is the only comparison worth making. OpenTofu resolves a local
    module source against the file declaring it, and Ansible resolves a
    relative roles_path against the directory holding ansible.cfg, so `base`
    differs per component and is passed in by the caller.
    """
    return pathlib.Path(base, declared).resolve()


def main():
    print(f"Reading the example at {EXAMPLE.relative_to(EXAMPLE.parent.parent)}/")

    print()
    print("One example, laid out as a separate consumer repository would be:")
    directories = sorted(
        {
            path.relative_to(EXAMPLES_ROOT).parts[0]
            for path in tracked(EXAMPLES_ROOT)
            if len(path.relative_to(EXAMPLES_ROOT).parts) > 1
        }
    )
    check(
        "examples/ holds exactly one example directory",
        directories == [EXAMPLE.name],
        [f"found: {', '.join(directories) or '(none)'}"],
    )
    for path in (REVISION_FILE, MAIN_TF, ANSIBLE_CFG, INVENTORY, PLAY):
        check(f"{path.relative_to(EXAMPLE)} exists", path.is_file())

    print()
    print("The pinned revision is one immutable full commit SHA:")
    declaration = yaml.safe_load(REVISION_FILE.read_text()) or {}
    revision = declaration.get("revision")
    checkout = declaration.get("checkout_path")
    check("toolkit-revision.yml declares a revision", isinstance(revision, str) and bool(revision))
    check(
        "the revision is a full 40-character commit SHA, not an abbreviation, branch, or tag",
        isinstance(revision, str) and bool(FULL_SHA.match(revision)),
        [f"declared: {revision!r}"],
    )
    check(
        "toolkit-revision.yml declares a relative checkout path",
        isinstance(checkout, str) and bool(checkout) and not pathlib.PurePosixPath(checkout).is_absolute(),
        [f"declared: {checkout!r}"],
    )

    print()
    print("Both components resolve from that one checkout:")
    modules = module_source()
    check(
        "the OpenTofu root declares exactly one module block",
        len(modules) == 1,
        [f"found: {[name for name, _ in modules]}"],
    )
    sources = [source for _, block in modules for source in block]
    check("that module block declares exactly one source", len(sources) == 1, [f"found: {sources}"])

    declared_source = sources[0] if len(sources) == 1 else None
    check(
        "the module source is a local path rather than a registry or remote address",
        isinstance(declared_source, str) and declared_source.startswith((".", "/")) and "::" not in declared_source,
        [f"declared: {declared_source!r}"],
    )

    declared_roles = roles_path()
    check(
        "ansible.cfg declares a roles_path",
        isinstance(declared_roles, str) and bool(declared_roles),
        [f"declared: {declared_roles!r}"],
    )
    check(
        "the roles_path names one directory rather than a search list",
        isinstance(declared_roles, str) and ":" not in declared_roles,
        [f"declared: {declared_roles!r}"],
    )

    if declared_source and declared_roles and isinstance(checkout, str):
        # OpenTofu resolves a local source against the directory of the file
        # declaring it; Ansible resolves a relative roles_path against the
        # directory holding ansible.cfg. Both are checked as they resolve.
        module_target = resolve(TOFU_ROOT, declared_source)
        roles_target = resolve(ANSIBLE_ROOT, declared_roles)
        checkout_root = resolve(EXAMPLE, checkout)

        check(
            f"the module source resolves to {MODULE_PATH_IN_CHECKOUT} inside the declared checkout",
            module_target == checkout_root / MODULE_PATH_IN_CHECKOUT,
            [f"resolves to: {module_target}", f"expected:    {checkout_root / MODULE_PATH_IN_CHECKOUT}"],
        )
        check(
            f"the roles_path resolves to {ROLES_PATH_IN_CHECKOUT} inside the declared checkout",
            roles_target == checkout_root / ROLES_PATH_IN_CHECKOUT,
            [f"resolves to: {roles_target}", f"expected:    {checkout_root / ROLES_PATH_IN_CHECKOUT}"],
        )
        # The two assertions above could each hold against a different
        # checkout, which is the drift this contract exists to prevent.
        check(
            "both components therefore resolve from the same checkout, so one commit determines both",
            module_target.parts[: len(checkout_root.parts)] == checkout_root.parts
            and roles_target.parts[: len(checkout_root.parts)] == checkout_root.parts,
            [f"module: {module_target}", f"roles:  {roles_target}", f"checkout: {checkout_root}"],
        )

    print()
    print("The play uses the role from that checkout, and the inventory is written by hand:")
    play = yaml.safe_load(PLAY.read_text()) or []
    roles_used = [
        entry["role"] if isinstance(entry, dict) else entry
        for item in play
        if isinstance(item, dict)
        for entry in item.get("roles") or []
    ]
    check(f"one play invokes the {ROLE} role", roles_used == [ROLE], [f"found: {roles_used}"])

    inventory = yaml.safe_load(INVENTORY.read_text()) or {}
    hosts = {
        name: variables or {}
        for group in inventory.values()
        if isinstance(group, dict)
        for name, variables in (group.get("hosts") or {}).items()
    }
    check("the inventory declares exactly one host", len(hosts) == 1, [f"found: {sorted(hosts)}"])
    for name, variables in hosts.items():
        check(
            f"{name} maps connection.host, connection.user, and connection.port explicitly",
            set(variables) == {"ansible_host", "ansible_user", "ansible_port"},
            [f"found: {sorted(variables)}"],
        )
    # A dynamic inventory would generate what the contract says a human writes.
    check(
        "the inventory is a static document rather than an inventory plugin",
        "plugin" not in inventory,
        [f"found keys: {sorted(inventory)}"],
    )

    print()
    print("The example owns no acquisition, orchestration, state, or secret mechanism:")
    present = sorted(
        f"{path.relative_to(EXAMPLE)} ({reason})"
        for path in example_files()
        for name, reason in FORBIDDEN_NAMES.items()
        if path.name == name
    )
    check("no file in the example is an acquisition or orchestration entry point", not present, present)

    suffixed = sorted(
        f"{path.relative_to(EXAMPLE)} ({reason})"
        for path in example_files()
        for suffix, reason in FORBIDDEN_SUFFIXES.items()
        if path.suffix == suffix
    )
    check("no state, plan, or key material is committed with the example", not suffixed, suffixed)

    # Anything runnable outside tests/ would be a mechanism the example
    # performs, and the contract leaves every runnable step to the consumer.
    #
    # The permission bit alone is not the test. `sh fetch.sh` runs a file that
    # was never marked executable, and a mode is easy to lose in a copy or a
    # checkout, so a script is recognised by what it is as well as by how it is
    # marked.
    runnable = sorted(
        str(path.relative_to(EXAMPLE))
        for path in example_files()
        if (EXAMPLE / "tests") not in path.parents
        and (path.suffix in SCRIPT_SUFFIXES or path.stat().st_mode & 0o111)
    )
    check("nothing outside tests/ is runnable, so the example performs nothing itself", not runnable, runnable)

    found_content = sorted(
        f"{path.relative_to(EXAMPLE)}: {reason}"
        for path in readable_files()
        for marker, reason in FORBIDDEN_CONTENT.items()
        if marker in path.read_text()
    )
    check("no file reads state, or carries secret material", not found_content, found_content)

    tofu = tofu_text()
    check(
        "the OpenTofu root declares no backend, leaving state custody to the consumer",
        not re.search(r'^\s*backend\s+"', tofu, re.MULTILINE),
    )
    provider_blocks = re.findall(r'provider\s+"proxmox"\s*\{([^}]*)\}', tofu)
    check("the OpenTofu root declares exactly one proxmox provider block", len(provider_blocks) == 1)
    populated = [body.strip() for body in provider_blocks if body.strip()]
    check(
        "that provider block is empty, so no endpoint or credential is published",
        len(provider_blocks) == 1 and not populated,
        populated,
    )

    print()
    print("Every concrete value is fictional or standards-reserved:")
    bad_addresses = sorted(
        f"{path.relative_to(EXAMPLE)}: {address}"
        for path in readable_files()
        for address in IPV4.findall(path.read_text())
        if not is_documentation_address(address)
    )
    check("every IPv4 address is reserved for documentation by RFC 5737", not bad_addresses, bad_addresses)

    # A URL ending a sentence carries the full stop into the capture, so the
    # punctuation a host can be followed by in prose is trimmed before the
    # comparison. Otherwise the check reports "opentofu.org." as a real place.
    bad_hosts = sorted(
        f"{path.relative_to(EXAMPLE)}: {host}"
        for path in readable_files()
        for pattern in (URL_HOST, AT_HOST)
        for match in pattern.findall(path.read_text())
        for host in [match.rstrip(".,;:!?)>]\"'")]
        if not is_allowed_host(host)
    )
    check("every host named in a URL or address is documentation-reserved or a source the example cites", not bad_hosts, bad_hosts)

    # The inventory is where a real address would do the most damage, so its
    # entries are checked against their own values rather than by pattern.
    reachable = sorted(
        f"{name}: {value}"
        for name, variables in hosts.items()
        for value in (name, variables.get("ansible_host"))
        if not is_fictional_host(value)
    )
    check("every inventory host name and address is fictional or standards-reserved", not reachable, reachable)

    print()
    if failures:
        print(f"{checks} checks, {failures} failure(s).", file=sys.stderr)
        return 1
    print(f"{checks} checks, 0 failures.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
