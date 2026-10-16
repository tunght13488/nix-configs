# Tasks

## 1. Flake input

- [ ] 1.1 Add the `pi` input to `flake.nix` (`github:lukasl-dev/pi.nix`, with `inputs.pi.inputs.nixpkgs.follows = "nixpkgs-unstable"`) and refresh only that input with `nix flake update pi`; verify `nix flake metadata` resolves the input and `flake.lock` pins it.

## 2. Home Manager module

- [ ] 2.1 Create `home-manager/pi.nix` enabling `programs.pi.coding-agent` with `jail.enable = true` and the core permission list from design D3 (four repo-root ro binds preceding the `.bare` rw binds and `mount-cwd`, `network`, full `/nix/store` ro, nix daemon socket, `/etc/nix`, `~/.cache/nix`, readonly `~/.config/gh`, openspec `~/.npm-global` binds, `~/.agents`, `add-runtime` `export HERDR_AGENT=pi`) with the D4 minimal gitconfig via `write-text` (identity duplicated from `~/.config/git/config`, `git@github.me:` insteadOf rewrite to https, `gh auth git-credential` helper); import it from `home-manager/home.nix` (alongside `inputs.pi.homeModules.default`); `git add` the new file before evaluation; verify `make home-build` evaluates cleanly. Note: run the first build with `NIX_CONFIG="extra-substituters = https://pi.cachix.org"` (plus `extra-trusted-public-keys` from the pi.nix README) to substitute the pi workspace instead of building it from source, until the system substituters in task 3.1 are active.
- [ ] 2.2 Add the project toolchain surface from design D8 to `home-manager/pi.nix`: language-cache rw binds (`~/.m2`, `~/.npm`, `~/.cache/yarn`, `~/.cache/composer`) with the host-side `add-runtime` mkdir, and `add-pkg-deps` with the `config.phpConfig._lib` PHP wrappers (`php81`/`php82`/`php83` + versioned Composers + defaults), `jdk8`, `maven363`, `nodejs_22` (ordered before `nodejs`), `yarn`, and `jq`; verify `make home-build` still evaluates cleanly.
- [ ] 2.3 Run `make format` and verify the changed `.nix` files pass `nixpkgs-fmt` with no diff.

## 3. System nix settings

- [ ] 3.1 Add `pi.cachix.org` and `nix-community.cachix.org` substituters and trusted public keys (values from the pi.nix README) to `nix.settings` in `nixos/configuration.nix`; run `make format`; verify `make os-build` evaluates cleanly and prints no warnings about the new settings.

## 4. Activation and explicit-path verification

- [ ] 4.1 Run `make os` and then `make home` from a fresh terminal (user-run, never agent-run); verify `~/.nix-profile/bin/pi --version` prints `1.2.0` while the old launcher still works (`~/.local/bin/pi --version` also prints `1.2.0`) — no regression until cutover.
- [ ] 4.2 From a fresh terminal, run the new binary by explicit path in a scratch directory (`~/.nix-profile/bin/pi`): verify the TUI renders (powerline footer extension visible), a model request succeeds, and `pi list` shows the three npm extensions resolved from `~/.pi/agent/npm` (`pi-web-access`, `pi-powerline-footer`, `@plannotator/pi-extension`).

## 5. Cutover and jailed verification

- [ ] 5.1 Remove the self-managed launcher (`rm ~/.local/bin/pi ~/.pi/agent/bin/pi`); verify a fresh shell resolves `command -v pi` to `~/.nix-profile/bin/pi` and `pi --version` works.
- [ ] 5.2 From a jailed session in this repo, verify the build/test surface: `make home-build` succeeds; `openspec list` succeeds; `gh auth status` and a `gh pr view` (any accessible repo) succeed; a real `git push` of a scratch branch succeeds over https (then delete the branch); `git log`/`git status`/commits work across the worktree `.bare`.
- [ ] 5.3 From the same jailed session, verify the denials: `ls ~/.aws`, `ls ~/.ssh`, `cat ~/.npmrc`, and `cat ~/.config/nix/nix.conf` all fail (paths absent); a connection attempt to `~/.config/herdr/herdr-client.sock` fails.
- [ ] 5.4 Run the jailed `pi` in a herdr pane and verify state visibility: herdr shows `working` while generating and `idle` after (and `blocked`, or the manifest idle fallback, on an approval prompt); `herdr agent explain` identifies the pane as pi via `HERDR_AGENT`; if foreground detection fails under bwrap, apply the herdr server fallback (`HERDR_PROCESS_DETECTION=child-groups`, server restart) from design's risk list and re-verify.
- [ ] 5.5 From jailed sessions in the project folders, verify project work (design D8): in `middleware_alpha`, run `php81 -v`, `php82 -v`, `php83 -v`, and the versioned Composer command the project's `composer.json` requires, and create a git commit (`.bare` rw); in `oms_backend_main`, run `java -version` (1.8), `mvn -version` (3.6.3), and `node --version` (22.x); in `oms_frontend_main`, run `yarn --version`; re-run one dependency-resolving command a second time and confirm it resolves from the persistent cache without a full re-download.

## 6. Retirement and cleanup

- [ ] 6.1 Once no live session uses the old release (all pi sessions restarted post-cutover), delete `~/.pi/agent/install`; verify `pi` still starts, `pi list` still resolves the npm extensions, and `pi update` reports that the package manager provides pi (no new `install/` directory is created).
- [ ] 6.2 Document the jail boundary for future agent sessions: note in the repo `AGENTS.md` (or the `home-manager/pi.nix` header comment) that `make update`, `make home`, and `make os` are host-side operations and credential paths are unreachable inside pi sessions; verify the note matches the behavior verified in 5.3.

## Workflow follow-up

- Archive the change after the review requirements are satisfied.
- Verify the archived `pi-coding-agent` spec (requirements land in the main spec with scenarios intact).
