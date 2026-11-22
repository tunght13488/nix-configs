# Tasks

## 1. Spikes (fail fast before rewriting)

- [x] 1.1 Sandbox smoke on this host: run `nix shell nixpkgs#nono` and verify `nono run --block-net --allow-cwd -- curl https://example.com` is refused while the shell itself starts
- [x] 1.2 Pi TUI spike: run host Pi under `nono run` with a minimal workspace-only profile; verify the TUI renders, the session answers a prompt, and Ctrl+G launches Neovim and returns
- [x] 1.3 gh credential spike: run `gh pr view` under nono with the `~/.pi/sandbox/gh-token` credential injected and endpoint rules applied; verify the request succeeds, a destructive endpoint is denied, and the token is absent from the sandboxed environment
- [x] 1.4 Nix spike: build a small derivation under nono with `/nix/store` read and the daemon socket granted; verify the build succeeds with Nix's own sandboxing enabled
- [x] 1.5 Herdr spike: run a sandboxed Pi session with `HERDR_AGENT=pi` and the herdr env passed through; verify the herdr sidebar shows working/blocked/idle for the pane

## 2. Module and wrapper skeleton

- [x] 2.1 Rewrite `home-manager/pi-sandbox.nix`: install `pkgs.nono` and the rewritten wrapper, deploy template directory, drop the Dockerfile and relay deployments; verify `make home-build` evaluates
- [x] 2.2 Reimplement `pi-box.sh` run path: generate the per-run overlay (workspace, worktree git dir, root AGENTS.md, herdr socket, gh token route) as `pi-box-overlay-<project>` and run `nono run --profile <project|pi-box> --extends <overlay> -- pi`; verify `pi-box -p "touch probe.txt"` creates `probe.txt` in the workspace owned by the host user
- [x] 2.3 Port the dynamic grant logic (nvim presence, worktree git common dir) into profile generation; verify a worktree run can `git status` and that a sibling project path cannot be read from the sandbox

## 3. Credentials, network, and command policy

- [x] 3.1 Wire gh-token credential injection with endpoint rules (GET issues/pulls, POST pulls on the work orgs); verify `gh pr view` works, a repo-delete call is denied, and the token never appears in the sandboxed environment
- [x] 3.2 Set the network groups (`llm_apis`, `github`, `package_registries`, `sigstore`, `documentation`) plus manifest `allow_domain`/open-port grants, and `DB_HOST=127.0.0.1` for the PHP templates; verify a request to an unlisted domain is refused and the MySQL port is reachable only when granted
- [x] 3.3 Enable privileged-command blocking and audit recording; verify `sudo` is refused even inside a shell chain and the denial appears in the session audit record
- [x] 3.4 Add the wrapper-scoped `GIT_CONFIG_*` insteadOf rewrite for `git@github.com:`; verify `git ls-remote git@github.com:ORG/REPO.git` works without an SSH agent while other SSH hosts are untouched

## 4. Herdr and restart-resume

- [x] 4.1 Pass `HERDR_ENV`/`HERDR_PANE_ID`/`HERDR_SOCKET_PATH` through nono's environment allowlist and delete `pi-herdr-relay.py`; verify a herdr-pane run reports agent states and no relay process exists
- [x] 4.2 Keep the zsh resume routing function and remove session-path mapping from the wrapper; verify a resumed `pi --session <host path>` in a restored pane starts sandboxed and resumes the session

## 5. Templates

- [x] 5.1 Rewrite the template catalog to manifests and fragments (default, php83, php82, java8, node22, nix-configs, knowledge-assistant) and delete the template Dockerfiles; verify `pi-box init --list` lists all seven templates
- [x] 5.2 Rework `pi-box init` to scaffold `pi-box.profile.json` only, preserving backup/force/non-tty semantics; verify interactive overwrite writes a timestamped backup and a non-tty run leaves existing files alone
- [x] 5.3 Give the nix-configs template its store/daemon grants and verify `make format` and `make os-build` succeed inside `pi-box` from this repository
- [x] 5.4 Update `home-manager/git.nix` ignores to cover only `pi-box.profile.json` and remove the `Dockerfile.pi` entry; verify `git status` in a scaffolded repo stays clean

## 6. Docs, cleanup, and integration

- [x] 6.1 Rewrite the pi-box section of AGENTS.md and the openwiki operations page for the nono flow; verify the documented commands match the implemented CLI
- [x] 6.2 End-to-end verification in this repository: `pi-box` with the nix-configs template, workspace edits visible on host, `~/.aws` and `~/.ssh` unreadable from the sandbox, and one provider request succeeds
- [x] 6.3 Delete `pi-sandbox.Dockerfile` and remove every remaining reference; verify `rg -l 'pi-sandbox|Dockerfile.pi|pi-herdr-relay'` returns no live references and `make home-build` passes

## Workflow follow-up

- Archive the change after the specs validate and the host applies the new home-manager generation (`make home`).
- Drop the `pi-nix-configs-nix` Docker volume and prune `pi-sandbox*` images once the switch is complete.
