# Security policy

## Supported versions

Security fixes are made in the latest release only. Upgrade by running the install command again:

```sh
curl -fsSL https://raw.githubusercontent.com/datashard-ai/mnem0nic/main/install.sh | sh
```

## Reporting a vulnerability

Please report security problems privately, through GitHub:
[report a vulnerability](https://github.com/datashard-ai/mnem0nic/security/advisories/new).
Don't open a public issue.

Please include:

- the mnem0nic version (`mnem0nic --version`) and your macOS version;
- what an attacker could do, and what they would need;
- the steps to reproduce it.

We will acknowledge your report, keep you informed as we investigate, and credit you in the release
notes unless you'd rather not be named.

## Scope

In scope: the `mnem0nic` binary, its install script, and the data it stores in
`~/.local/share/mnem0nic`.

Out of scope: Claude Code, Codex and their providers' services, and Datashard, which have their own
security policies.
