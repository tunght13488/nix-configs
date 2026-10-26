# Tasks

## 1. Shared GitHub transport rewrite

- [ ] 1.1 Add `[url "https://github.com/"]` with `insteadOf = git@github.com:` to the baked `/root/.gitconfig` in `home-manager/pi-sandbox.Dockerfile`. Build the base image and verify its Git config contains exactly this GitHub prefix rewrite plus the existing HTTPS credential helper; confirm the rewrite does not add a rule for other SSH hosts.
- [ ] 1.2 Update the pi-box section in `AGENTS.md` to document that `git@github.com:` URLs use HTTPS with the existing `gh` helper, while other SSH remotes and `ssh://` GitHub URLs are not covered. Verify the old blanket instruction to use HTTPS for GitHub is replaced and the scope is explicit.
- [ ] 1.3 From a pi-box run with the configured token, run `git ls-remote git@github.com:Secretlabsg/netsuite-middleware.git HEAD` and verify it succeeds. Verify a temporary checkout's `git remote get-url origin` remains in SSH form after the operation.

## 2. ka_alpha project image

- [ ] 2.1 Run `pi-box init` in `/home/tung/code/knowledge-assistant/ka_alpha` if its scaffold files are absent, then make `Dockerfile.pi` extend `pi-sandbox` and install `@sysid/mmdlint`. Build the project image and verify `mmdlint` is available and successfully validates a Mermaid-containing Markdown document from the workspace; verify the generated `Dockerfile.pi` and `pi-box.toml` remain globally ignored.

## 3. Repository sync integration

- [ ] 3.1 In the ka_alpha sandbox, run read-only `git ls-remote` against each of the seven GitHub SCP-style URLs configured in `scripts/sync-repos.sh` (middleware, oms-backend, oms-frontend, prbot, v3, shopify-proxy, hrbot). Verify all succeed using the HTTPS credential helper, no SSH/1Password mount is present, and each configured `origin` remains `git@github.com:`.
- [ ] 3.2 Before running the sync script, check `git status --porcelain` in all seven linked repositories. Proceed only if every checkout is clean; if any is dirty, stop and ask the user rather than allowing the script's `git reset --hard` to discard work.
- [ ] 3.3 If task 3.2 passes, run `./scripts/sync-repos.sh` inside pi-box. Verify each repository is on its configured default branch and `HEAD` matches `origin/<branch>`, all seven syncs complete without SSH errors, and the remotes remain in SSH form.
