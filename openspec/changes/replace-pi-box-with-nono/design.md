# Design

## Context

pi-box is currently a rootless-Docker sandbox: a `pi-box` shell wrapper (481 lines) builds a shared base image and a per-project image, mounts the granted paths, starts a herdr relay (223-line Python), and exports a write-capable GitHub PAT into the container. The host is NixOS with rootless Docker enabled and Linux 5.13+ (Landlock available). `nono` 0.80.0 is packaged in nixpkgs 26.05. Motivation: see proposal.md.

## Goals / Non-Goals

**Goals:**

- Keep the `pi-box` name, UX, `init` semantics (backups, force, no-tty safety), and herdr restart-resume routing.
- Express the current grant model as nono grants: absence semantics (ungranted paths are inaccessible), never granting `~/.aws`, `~/.ssh`, the 1Password socket.
- Broker the GitHub token through nono credential injection with endpoint rules.
- Default-deny network with an allowlist.

**Non-Goals:**

- No container fallback path; rootless Docker stays configured for other uses but pi-box stops calling it.
- No per-tool command-sandbox splitting beyond the gh endpoint rules and privileged-command blocking (finer tool sandboxing is a future change).
- No SPIFFE/OAuth-capture flows, no pack publishing, no skill attestation.

## Decisions

### 1. Generated per-run profile, not a checked-in profile

`pi-box` composes the session profile at launch: defaults (shared grants, network groups, gh credential rules) + template fragment (when the template ships one) + `pi-box.toml` overrides, written to `~/.pi/sandbox/runtime/` and passed with `nono run --profile <path> -- pi ...`. Alternatives: a static per-project profile file would duplicate the default block in every project and could not compute dynamic grants (worktree git common dir, `~/.config/nvim` existence); nono packs would require publishing and distributing local machine policy.

### 2. Filesystem grants mirror the current mount set

Workspace (rw), `~/.pi/agent` (rw), `~/.config/git` and `~/.config/gh` (ro), `~/.config/nvim` (ro, when present), `/tmp` and `~/.cache` (rw), and the git common dir (rw) when the workspace's `.git` file points outside it. The wrapper keeps the existing detection logic, now emitting grants instead of `--volume` flags. Nono's capability model makes ungranted paths unreadable, preserving the current confidentiality posture (one accepted difference: `stat`/`access` succeed on ungranted paths, so file *existence* leaks; contents do not).

### 3. gh token via credential injection with endpoint rules

The existing `~/.pi/sandbox/gh-token` file (mode 600, check kept in the wrapper) becomes a nono credential source declared in the generated profile. Endpoint rules allow: GET on issues/pulls endpoints, POST on `/repos/{work-orgs}/pulls`; destructive endpoints (repo delete, secrets, org settings) are not listed and are denied by default. The token is injected at request time and never appears in the sandboxed environment or the profile. Alternatives: keep exporting `GH_TOKEN` (no endpoint control - the exact risk this change targets); use nono's keystore/1Password backends (they work but the token file is already the established provisioning path and needs no agent-side changes).

### 4. Network allowlist from nono preset groups

The profile uses the `llm_apis`, `github`, `package_registries`, `sigstore`, and `documentation` groups, plus per-manifest `allow_domain` additions; everything else is denied. The `DB_HOST=host.docker.internal` workaround disappears: `php83`/`php82` set `DB_HOST=127.0.0.1` and declare the MySQL port as an open-port grant so localhost outbound is explicit.

### 5. GitHub SSH-remote rewrite moves into the wrapper

The container-side `/root/.gitconfig` rewrite is replaced by wrapper-exported `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_n` variables (`url.https://github.com/.insteadOf=git@github.com:`), scoped to the sandboxed invocation only. Alternatives: profile-scoped gitconfig file (extra file lifecycle, same effect); dropping the rewrite (breaks the existing spec requirement).

### 6. Herdr integration without a relay

The sandboxed process is host-native, so it connects to the herdr socket directly, like host Pi. The wrapper keeps exporting `HERDR_AGENT=pi` for screen-manifest detection and passes `HERDR_ENV`/`HERDR_PANE_ID`/`HERDR_SOCKET_PATH` through nono's environment allowlist. The relay script is deleted; session-path mapping is deleted (paths are host paths).

### 7. Templates become manifests plus optional fragments

Each template directory ships `pi-box.toml` (the per-project manifest, same `init` UX and gitignore treatment) and may ship a `profile.json` fragment merged into the generated profile. Toolchain templates stop provisioning toolchains: the host home-manager toolchains and project devShells supply PHP 8.2/8.3, JDK 8, Node 22, and the Nix toolchain. `java8` grants `~/.m2` (host cache persists natively, no volume). `nix-configs` drops the private store: `nix build` runs as a client against the host daemon (which sandboxes builds in its own daemon-side sandbox, unaffected by the client's Landlock profile); the profile grants `/nix/store` read and the daemon socket. `knowledge-assistant` pins `mmdlint` via `npx` (npm registry is in `package_registries`).

### 8. Module shape

`home-manager/pi-sandbox.nix` installs `pkgs.nono` and the rewritten `pi-box` wrapper, deploys the template directory and a shared `defaults` profile fragment, and keeps the gh-token documentation. The `piVersion` image pin is removed; the home-manager Pi package is the single source of the sandboxed Pi version.

## Risks / Trade-offs

- [nono is pre-1.0 with fast version churn and schema drift] → Pin the version in home-manager; keep all profile generation in one function so a schema change is a single edit; bump deliberately with a test run.
- [TUI behavior under the sandbox (TTY, SIGWINCH, Ctrl+G editor spawn)] → Spike early in implementation; if the TUI breaks, investigate nono's pty handling before proceeding.
- [Landlock or seccomp restrictions on this host] → Spike first (`nono run --block-net --allow-cwd -- <command>`); fail with a clear error if unsupported, never degrade silently.
- [gh OS-keyring auth inside the sandbox (D-Bus reachability)] → The injected-token path is the primary mechanism and does not need the keyring; if the host `gh` still tries the keyring first, wrapper config pins `gh` to the injected credential path.
- [Capability model vs container boundary] → nono runs as the same user and is not a boundary against kernel exploits (its own docs say so). Accepted: the threat model is a semi-trusted agent, not kernel escape. The proposal notes this trade-off.
- [`stat`/`access` reveal ungranted file existence] → Accepted; nono documents this as not a data-exfiltration vector.

## Migration Plan

1. Implement the wrapper rewrite, module changes, and template migration in the config repo; `make home-build`/`make home` to activate (user-run, as usual).
2. Per project/worktree: run `pi-box init --force <template>` once (backups are written; old `Dockerfile.pi` files are left for the user to delete).
3. After the switch, the `pi-nix-configs-nix` Docker volume can be dropped; base/project images can be pruned.
4. Rollback: revert the commit and re-apply home-manager; the old wrapper, Dockerfile, and relay are in git history.

## Open Questions

- Exact nono version to pin at implementation time (latest in 26.05 at that point; possibly an overlay bump for endpoint-rule fixes).
- Whether the LLM-provider allowlist should be derived from the providers in `~/.pi/agent/auth.json` instead of a static list (defer: static list first, derivation as a follow-up).
- `mmdlint` delivery: `npx` (chosen) vs a home-manager npm install (fallback if npx proves flaky inside the sandbox).
