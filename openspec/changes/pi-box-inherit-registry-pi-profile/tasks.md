# Tasks

## 1. Inherit the registry profile and expose OpenSpec

- [ ] 1.1 Update `home-manager/pi-sandbox.nix` to extend `nolabs-ai/pi`, remove pi-box's `developer` network profile and static domain allowlist, and add read-only grants for `~/.npm-global/bin` and the OpenSpec package directory; update `launcher_path` to retain only the exact npm global bin entry beyond Nix store paths. Verify with `make format`, `make home-build`, and `bash -n home-manager/pi-box.sh`.
- [ ] 1.2 Update the pi-box section in `AGENTS.md` to document the inherited `~/.pi` and `~/.cache` read-write grants, default-allow egress, the `nono pull nolabs-ai/pi` prerequisite, and OpenSpec availability; verify it no longer describes the base as default-deny or says `~/.cache` is never granted.

## 2. Move and protect the GitHub token

- [ ] 2.1 Change `home-manager/pi-box.sh` to use `~/.config/nono/credentials/pi-box-gh-token` for the broker route and fail before launch if `~/.pi/sandbox/gh-token` still exists; retain the route's endpoint rules. Verify shell syntax and use a temporary home with a legacy token to assert the wrapper exits with a migration message before invoking Nono.
- [ ] 2.2 Update `AGENTS.md` token setup and migration instructions for the new path, directory mode `700`, and file mode `600`; verify the old path appears only in the migration and legacy-guard documentation.
- [ ] 2.3 Before Home Manager activation, have the user move any existing token to the new host-side path and remove the old file; verify the new file's location and permissions and the old path's absence without printing or reading the token contents.

## 3. Validate the deployed sandbox

- [ ] 3.1 After a human applies Home Manager, run `nono profile validate pi-box` and inspect `nono profile show pi-box --json`; verify it extends `nolabs-ai/pi`, has default-allow networking, and inherits the expected `~/.pi` and `~/.cache` grants. Use `nono why` to confirm the new token path is denied and the OpenSpec package is readable but not writable.
- [ ] 3.2 Run `openspec --version` and connect to `https://pi.dev` from inside pi-box; verify an otherwise unlisted public destination is reachable. Confirm the brokered GitHub route remains configured and a read-only `gh pr view` works; do not issue a live destructive GitHub API request.
