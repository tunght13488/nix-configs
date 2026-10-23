# Tasks

## 1. Home-manager module scaffold

- [x] 1.1 Create `home-manager/pi-sandbox.nix` with a header comment (purpose, consumers) that installs the `pi-box` script and deploys `home-manager/pi-sandbox.Dockerfile` to `~/.pi/sandbox/Dockerfile` via `home.file`; import the module in `home-manager/home.nix`. Verify `make home-build` succeeds.

## 2. Base image

- [x] 2.1 Write `home-manager/pi-sandbox.Dockerfile`: `FROM node:24-slim`; apt-install `ripgrep`, `fd-find`, `git`, `gh`; bake `/root/.gitconfig` that resets the github.com credential helper to `gh auth git-credential` and neutralizes `core.editor`/`core.askpass`; install Pi last via `ARG PI_VERSION` (pinned to the current host version). Verify `docker build -f home-manager/pi-sandbox.Dockerfile -t pi-sandbox .` succeeds and `docker run --rm pi-sandbox pi --version` prints the pinned version.
- [x] 2.2 Verify base image tooling and git overrides: `docker run --rm pi-sandbox sh -lc 'command -v rg fd git gh && git config --get credential.https://github.com.helper && git var GIT_EDITOR'` shows all four binaries, the in-container gh helper, and a container-safe editor (not `nvim`/`vscode`).

## 3. pi-box wrapper: run path

- [x] 3.1 Implement the `pi-box` run path: always `docker build` the base image (from `~/.pi/sandbox/Dockerfile`) and, when `Dockerfile.pi` exists, the project image `pi-<dirname>` (falling back to the base image when absent); then `docker run --rm -it` with the default mounts — workspace at its absolute path (rw), `~/.pi/agent` → `/root/.pi/agent` (rw), `~/.config/git` (ro), `~/.config/gh` (ro) — plus `--add-host host.docker.internal:host-gateway` and a runtime-resolved bind mount of the real `AGENTS.md` target over `/root/.pi/agent/AGENTS.md`. Verify in a scratch project: `docker inspect` on a started sandbox lists exactly the default host-backed mounts, and `/root/.pi/agent/AGENTS.md` is readable with host content.
- [x] 3.2 Verify the never-grants and credential stance of the default run: inside the sandbox `~/.aws`, `~/.ssh`, and the 1Password socket path do not exist, and `env` shows no provider key variables (`OPENCODE_API_KEY` etc.). Verify a workspace file created in the sandbox appears on the host owned by `tung`.

## 4. pi-box wrapper: init, manifest, docs

- [x] 4.1 Implement `pi-box init`: write `Dockerfile.pi` and `pi-box.toml` from embedded templates when absent, never overwrite. Verify in a scratch dir: first run creates both files, second run exits without modifying them.
- [x] 4.2 Implement `pi-box.toml` grants: `ports` (published ports), `env` (extra env vars), `mounts` (extra read-only host paths), `gh` (bool, default true; false drops the `~/.config/gh` mount). Verify with a scratch manifest: `docker inspect` shows the declared port/env/mounts, an undeclared grant is absent, and `gh = false` removes the gh mount.
- [x] 4.3 Document `pi-box` in the repo root `AGENTS.md`: what it is, `pi-box` / `pi-box init` usage, the manifest schema, the new-worktree ritual, and the rebuild-on-Pi-upgrade note. Verify the documented commands run as written.

## 5. Global gitignore

- [x] 5.1 Add `pi-box.toml` and `Dockerfile.pi` to `programs.git.ignores` in `home-manager/git.nix`. Verify `make home-build` succeeds and, after the user applies with `make home`, `git check-ignore Dockerfile.pi pi-box.toml` matches both in any repository (host and container share `~/.config/git/ignore` via the mount).

## 6. Pilot: middleware_alpha

- [x] 6.1 Run `pi-box init` in `/home/tung/code/netsuite-middleware/middleware_alpha`, then set `Dockerfile.pi` to `FROM pi-sandbox` plus the sury.org apt repo, `php8.3`, `php8.3-soap`, and composer; set `pi-box.toml` to `env.DB_HOST = "host.docker.internal"`. Verify `pi-box` builds `pi-middleware_alpha` and starts a Pi TUI with the workspace mounted at its absolute path.
- [x] 6.2 Verify the pilot toolchain and DB grant in the sandbox: `php -v` reports 8.3, `composer` runs, `./vendor/bin/phpunit --testsuite=Unit` passes, and a feature-suite run connects to host MySQL (`netsuite_alpha`). If the connection is rejected on host matching, fix the MySQL account host pattern (`tung`@`localhost` vs `tung`@`%`) and re-verify.

## 7. Integration verification

- [x] 7.1 Verify credential-free auth: with no env credentials, sandboxed Pi completes a model request via the shared `~/.pi/agent/auth.json` (OpenCode Go and the GitHub Copilot default model), and `gh pr view` on a repo of the pilot project works via the read-only `~/.config/gh` mount without write errors from `gh auth status`.
- [x] 7.2 Verify git identity in the sandbox: a commit made by sandboxed Pi carries the host author name/email, and `git ls-remote` on a private HTTPS remote authenticates via the in-container gh credential helper.
- [x] 7.3 Verify shared state both ways: a session recorded in the sandbox is listed by host Pi, and a workspace trust decision made on the host is honored in the sandbox.
- [x] 7.4 Verify host-installed Pi packages on Debian node: `pi-subagents`, `pi-web-access`, `@plannotator/pi-extension`, and `pi-powerline-footer` load without native-addon failures; record any that break and apply the fallback (bake into base image or exclude per project) if needed.
- [x] 7.5 Verify layer reuse: building a second worktree's image with identical `Dockerfile.pi` content is a near-instant cached build, and editing `Dockerfile.pi` rebuilds only project layers while base layers are reused.

## Workflow follow-up

- Ask the user to run `make home` to activate, then re-run the verifications that depend on activation (deployed `~/.pi/sandbox/Dockerfile`, gitignore entries).
- Archive the change once all tasks are complete: `openspec archive add-pi-box-sandbox`.
