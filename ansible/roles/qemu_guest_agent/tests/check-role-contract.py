#!/usr/bin/env python3
"""Check the qemu_guest_agent role's declared package and service contract.

The role's whole value is that two pieces of guest state are declared through
Ansible's own modules: the qemu-guest-agent package is present, and its service
is running. This reads what the role executes and asserts exactly that, plus the
boundaries it is supposed to keep - no shell commands standing in for modules,
no privilege configuration taken away from the consumer, and no reference to
OpenTofu anywhere in what the role runs.

Coverage is the point of how this is written. Checking tasks/main.yml alone
would let an included task file or a handler carry a shell command or a become
the role claims not to have, so every task and handler file is read, tasks
nested inside block, rescue and always are walked, and anything that would run
content this has not read is itself a failure: an include naming a file it has
not parsed - which is not the same as one outside the role, since most of a role
is never read as tasks - a module named indirectly through action or
local_action, another role pulled in, or a role dependency declared in meta. Otherwise "everything the role
executes" would not be a claim this can make. Whether an include stays inside is decided by
resolving its path rather than by looking for ".." in the text of it, and the
table at the end of the run asserts that classification against fictional paths,
so the rule cannot quietly stop working.

It contacts no guest, needs no credentials, and runs nothing. It is evidence
about what the role declares, never that a package was installed or that a
service came up.

Usage: python3 ansible/roles/qemu_guest_agent/tests/check-role-contract.py
Requires: PyYAML, which comes with the declared ansible-core.
"""

import os
import pathlib
import sys

import yaml

ROLE = pathlib.Path(__file__).resolve().parent.parent

PACKAGE = "qemu-guest-agent"
SERVICE = "qemu-guest-agent"

PACKAGE_MODULE = "ansible.builtin.package"
SERVICE_MODULE = "ansible.builtin.systemd_service"

# Modules that would run a command instead of describing state.
COMMAND_MODULES = {
    "command",
    "shell",
    "raw",
    "script",
    "ansible.builtin.command",
    "ansible.builtin.shell",
    "ansible.builtin.raw",
    "ansible.builtin.script",
}

INCLUDE_MODULES = {
    "include",
    "include_tasks",
    "import_tasks",
    "ansible.builtin.include",
    "ansible.builtin.include_tasks",
    "ansible.builtin.import_tasks",
}

# A task can name its module indirectly, and `action: ansible.builtin.shell`
# runs a shell command while carrying none of the module keys looked for above.
# Rather than parse those forms, the role is held to naming its modules
# directly: with two tasks, there is no reason to do otherwise, and it keeps
# what the role runs legible to a reader as well as to this check.
INDIRECT_KEYS = {"action", "local_action"}

# Pulling in another role would execute content this check never reads, and no
# amount of path resolution would help: the tasks live somewhere else entirely.
# This role has no business doing it.
ROLE_INCLUDE_MODULES = {
    "include_role",
    "import_role",
    "ansible.builtin.include_role",
    "ansible.builtin.import_role",
}

# Where Ansible finds things the role executes.
TASK_DIRECTORIES = ("tasks", "handlers")

# Directories holding what the role executes. The README is excluded on
# purpose: it describes the boundary with OpenTofu in prose, and saying so is
# not a dependency.
EXECUTED_DIRECTORIES = ("tasks", "handlers", "defaults", "vars", "meta", "files", "templates")

FOREIGN_MARKERS = ("tofu", "terraform", "tfstate")

checks = 0
failures = 0


def check(description, ok):
    global checks, failures
    checks += 1
    if not ok:
        failures += 1
    print(f"{'ok  ' if ok else 'FAIL'} {description}")


def yaml_files(directories):
    for directory in directories:
        for path in sorted((ROLE / directory).rglob("*")):
            if path.is_file() and path.suffix in (".yml", ".yaml"):
                yield path


def walk(tasks):
    """Yield every task, including those nested in block, rescue and always."""
    for task in tasks or []:
        if not isinstance(task, dict):
            continue
        yield task
        for section in ("block", "rescue", "always"):
            yield from walk(task.get(section))


def load_tasks():
    """Every task the role can execute, paired with the file declaring it."""
    for path in yaml_files(TASK_DIRECTORIES):
        loaded = yaml.safe_load(path.read_text())
        if not isinstance(loaded, list):
            continue
        for task in walk(loaded):
            yield path.relative_to(ROLE), task


def using(tasks, module):
    return [(path, task) for path, task in tasks if module in task]


def include_targets(task):
    """The files a task includes, as written."""
    for module in INCLUDE_MODULES & set(task):
        arguments = task[module]
        target = arguments.get("file") if isinstance(arguments, dict) else arguments
        if target is not None:
            yield target


def include_is_read(declaring_file, target, read_files):
    """Whether an include names one of the files this check actually parsed.

    "Under the role" is not the test, because most of the role is not read as
    tasks: a file in defaults/ is inside the role and never parsed for tasks,
    so an include pointing there would run a task this check never saw. The
    test is membership in the set of files it read, which is also why an
    absolute path, a target assembled at run time from a variable, and a file
    that does not exist all fail - none of them names something read.

    Ansible resolves a relative include against the directory of the file
    including it, so that is what this resolves against.
    """
    if not isinstance(target, str) or "{{" in target or "{%" in target:
        return False
    if pathlib.PurePosixPath(target).is_absolute():
        return False
    resolved = pathlib.Path(os.path.normpath(ROLE / declaring_file / ".." / target))
    return resolved in read_files


# Include targets and whether each one names a file this check reads. Only the
# first exists. The rest carry fictional names precisely so that they cannot
# come to exist: a row asserting "unread" would otherwise start failing the day
# somebody legitimately added a file of that name. Two weakenings in particular fail here
# rather than silently widening what goes unread: looking for ".." in the text
# rather than resolving the path, and accepting anything under the role rather
# than the files actually parsed.
INCLUDE_CASES = (
    ("tasks/main.yml", "main.yml", True),
    ("tasks/main.yml", "../defaults/fictional-hidden.yml", False),
    ("tasks/main.yml", "fictional-absent.yml", False),
    ("tasks/main.yml", "../../fictional_role/tasks/main.yml", False),
    ("tasks/main.yml", "/tmp/fictional-outside.yml", False),
    ("tasks/main.yml", "{{ fictional_path }}/fictional.yml", False),
)


def main():
    task_files = [path.relative_to(ROLE) for path in yaml_files(TASK_DIRECTORIES)]
    tasks = list(load_tasks())

    print(f"Reading {len(tasks)} task(s) in {len(task_files)} file(s): " + ", ".join(str(p) for p in task_files))
    check("the role declares tasks", bool(tasks))
    if not tasks:
        return 1

    print()
    print("The package is installed through Ansible's package management:")
    package_tasks = using(tasks, PACKAGE_MODULE)
    check(f"exactly one task in the role uses {PACKAGE_MODULE}", len(package_tasks) == 1)
    if package_tasks:
        arguments = package_tasks[0][1][PACKAGE_MODULE]
        check(f"it names the {PACKAGE} package", arguments.get("name") == PACKAGE)
        check("it asks for state: present", arguments.get("state") == "present")

    print()
    print("The service is running, and enabled where the packaging supports it:")
    service_tasks = using(tasks, SERVICE_MODULE)
    check(f"exactly one task in the role uses {SERVICE_MODULE}", len(service_tasks) == 1)
    if service_tasks:
        arguments = service_tasks[0][1][SERVICE_MODULE]
        check(f"it names the {SERVICE} service", arguments.get("name") == SERVICE)
        check("it enables the service where the packaging allows it", arguments.get("enabled") is True)
        check("it asks for state: started", arguments.get("state") == "started")

    print()
    print("The boundaries the role keeps, across every task and handler file:")
    commanding = [(path, task) for path, task in tasks if COMMAND_MODULES & set(task)]
    check(
        "no task runs a command instead of describing state",
        not commanding,
    )
    for path, task in commanding:
        print(f"     {path}: {task.get('name', '<unnamed>')}")

    escalating = [(path, task) for path, task in tasks if "become" in task]
    check(
        "no task declares become, so privilege stays the consumer's decision",
        not escalating,
    )
    for path, task in escalating:
        print(f"     {path}: {task.get('name', '<unnamed>')}")

    # An include naming a file this check never reads would quietly make the
    # coverage above untrue, whatever the shape of its path.
    read_files = {path.resolve() for path in yaml_files(TASK_DIRECTORIES)}
    outside = [
        (path, target)
        for path, task in tasks
        for target in include_targets(task)
        if not include_is_read(path, target, read_files)
    ]
    check("every include names a file this check has read, so nothing it executes goes unread", not outside)
    for path, target in outside:
        print(f"     {path}: {target}")

    indirect = [(path, task) for path, task in tasks if INDIRECT_KEYS & set(task)]
    check("every task names its module directly, rather than through action or local_action", not indirect)
    for path, task in indirect:
        print(f"     {path}: {task.get('name', '<unnamed>')}")

    including_roles = [(path, task) for path, task in tasks if ROLE_INCLUDE_MODULES & set(task)]
    check("no task pulls in another role, whose tasks would go unread", not including_roles)
    for path, task in including_roles:
        print(f"     {path}: {task.get('name', '<unnamed>')}")

    # A role dependency runs another role's tasks before this one's, which this
    # check never reads. It is the same hole as include_role, one directory over.
    metadata = ROLE / "meta" / "main.yml"
    dependencies = []
    if metadata.is_file():
        loaded = yaml.safe_load(metadata.read_text()) or {}
        if isinstance(loaded, dict):
            dependencies = loaded.get("dependencies") or []
    check("the role declares no role dependencies, whose tasks would go unread", not dependencies)
    for dependency in dependencies:
        print(f"     meta/main.yml: {dependency}")

    executed_files = [
        path
        for directory in EXECUTED_DIRECTORIES
        for path in sorted((ROLE / directory).rglob("*"))
        if path.is_file()
    ]
    check("the role has files to execute", bool(executed_files))
    for path in executed_files:
        content = path.read_text().lower()
        found = [marker for marker in FOREIGN_MARKERS if marker in content]
        check(
            f"{path.relative_to(ROLE)} names no OpenTofu state, output, or provider",
            not found,
        )

    print()
    print("How the include check classifies targets:")
    for declaring_file, target, expected in INCLUDE_CASES:
        verdict = "read" if expected else "unread"
        check(
            f"{target} included from {declaring_file} is {verdict}",
            include_is_read(declaring_file, target, read_files) == expected,
        )

    print()
    if failures:
        print(f"{checks} checks, {failures} failure(s).", file=sys.stderr)
        return 1
    print(f"{checks} checks, 0 failures.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
