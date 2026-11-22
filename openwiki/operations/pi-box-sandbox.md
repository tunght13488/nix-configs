---
type: operational sandbox guide
title: Pi-Box Capability Sandbox
description: Explains how Home Manager installs the pi-box wrapper and how it generates a per-run nono profile that grants the workspace, shared Pi state, git/gh configuration and caches, restricts network to an allowlist, and brokers the GitHub token behind endpoint rules.
tags: [pi-box, nono, Landlock, Home Manager, sandboxing, credentials]
verified:
  - by: openwiki/0.7.2
    at: 2026-11-22T00:00:00.000Z
sources:
  - id: openwiki-source-pibox-sh
    resource: repo://home-manager/pi-box.sh
  - id: openwiki-source-pibox-nix
    resource: repo://home-manager/pi-sandbox.nix
  - id: openwiki-source-pibox-default-manifest
    resource: repo://home-manager/pi-box-templates/default/pi-box.profile.json
---

# Pi-Box Capability Sandbox

`pi-box` is the project-local launcher for running the Pi coding agent under a nono capability
sandbox. Home Manager installs the wrapper and deploys the template catalog under
`~/.pi/sandbox`; nono enforces the grant set with Landlock, so ungranted host paths are
unreadable rather than merely unmounted, and the session runs as the invoking host user in the
project directory. No container or image is involved.

> Regenerate this page with the OpenWiki workflow; it is maintained from
> `home-manager/pi-box.sh`, `home-manager/pi-sandbox.nix`, and `home-manager/pi-box-templates/`.

## Deployment

`home-manager/pi-sandbox.nix` installs `pi-box` with `python3` (profile generation) and `nono`
on its `PATH`, and deploys `~/.pi/sandbox/templates` as a recursive tree of store-backed files
from `home-manager/pi-box-templates`. Because the scaffold name `pi-box.profile.json` is
globally ignored by Git, template files must be force-added or the flake will not see them.

## Run flow and profile generation

```text
pi-box
  |
  +-- generate overlay ~/.config/nono/profiles/pi-box-overlay-<project>.json
  |     filesystem.allow: workspace, worktree git dir
  |     filesystem.read_file: repository root AGENTS.md
  |     filesystem.unix_socket: herdr socket
  |     network: gh token route (credentials + endpoint rules) when the token file exists
  +-- write launcher (PATH + TMPDIR)
  +-- exec nono run --profile <project pi-box.profile.json | pi-box>
        --extends pi-box-overlay-<project> -- <launcher> <args>

nono resolves the project profile, its `extends: pi-box` base
(~/.config/nono/profiles/pi-box.json, deployed by home-manager: default grants, network
allowlist, environment denies) and the --extends overlay, and unions the filesystem grants.
```

`pi-box profile` prints the overlay; the base profile next to it is the rest of the policy.
Together they are the quickest way to audit what a project actually grants.

## `init`: scaffolding without silent data loss

`pi-box init [--force] [template]` copies `templates/<template>/pi-box.profile.json` into the
project, defaulting to `default`. An existing file is backed up to
`pi-box.profile.json.<YYYYmmdd-HHMMSS>.bak` only after a single interactive confirmation or
when `--force` is passed; without a terminal the file is left untouched. The destination is
removed before copying so a project symlink cannot redirect the write outside the project.
`--list` prints the templates that ship a profile, and an unknown template fails before
writing anything.

## Project profile

`pi-box.profile.json` is a standard nono profile (`extends: default`, validate with
`nono profile validate`). The wrapper merges exactly these fields over the generated
defaults and refuses any other field:

- `filesystem.allow` / `read` / `read_file` / `unix_socket`: extra grants (Maven, npm and yarn
  stores, the Nix daemon socket);
- `network.connect_port` / `listen_port` / `open_port` / `allow_domain` / `deny_domain`: ports
  and domains, such as a host MySQL on 3306;
- `environment.set_vars`: extra environment values, such as `DB_HOST = "127.0.0.1"`.

Anything else — `filesystem.write`, `commands`, `security`, a leftover `volumes` or
`privileged` — fails the run with a clear error, because a silently ignored grant reads like
it applies.

## Security boundary

Default grants are the project directory (read-write), `~/.pi/agent` (read-write, sharing
Pi's credentials, settings, sessions and trust), `~/.cache` (read-write), `/nix/store`
(read-only, for the targets of Home Manager's symlinks), and `~/.config/git`,
`~/.config/gh`, `~/.config/nvim` (read-only). `~/.aws`, `~/.ssh`, the 1Password agent socket
and every other host path are not granted, so reads fail with `EACCES` at the kernel.

Network is default-deny: the `developer` nono network profile allows LLM APIs, package
registries, GitHub and documentation, and everything else fails closed through the local
proxy. `nono audit list` and `nono audit show` report sessions and blocked requests.

### GitHub token brokering

`~/.pi/sandbox/gh-token` (mode 600) is declared as a nono credential route, not mounted. The
sandboxed `gh` sees a phantom token in `GH_TOKEN`; the supervisor reads the file and swaps in
the real token per request, subject to endpoint rules that allow `GET /user`, `GET /repos/**`,
`GET /search/**`, `GET /notifications`, `POST /repos/*/pulls` and `POST /graphql`. Every
DELETE or PATCH is refused. The GraphQL rule is the known loose end: path filtering cannot
distinguish a query from a mutation. If the file is absent the sandbox still starts and `gh`
stays unauthenticated.

## Operational checklist and safe changes

1. Apply Home Manager before relying on a new template or wrapper: a missing deployed template
   produces an actionable error.
2. Use `pi-box profile` to inspect a project's effective policy before trusting it.
3. Use `pi-box init --list` to discover templates, and `--force` only when replacing a local
   manifest is intended.
4. Treat changes to default grants, endpoint rules, token handling and Git URL rewriting as
   security-sensitive, and verify both a plain repository and an external Git common
   directory.
