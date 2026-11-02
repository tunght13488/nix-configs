# Design

## Context

See proposal.md for motivation. `flake.nix` already selects `nixos-26.05` and `home-manager/release-26.05`; `home-manager.inputs.nixpkgs.follows = "nixpkgs"` keeps both configurations on the same nixpkgs input. `flake.lock` fixes the exact revisions. The NixOS and standalone Home Manager outputs are built separately by `make os-build` and `make home-build`.

## Goals / Non-Goals

**Goals:**

- Refresh the locked revisions of the root `nixpkgs` and `home-manager` inputs on their current 26.05 branches.
- Remove PHP 8.1 so the `filter` extension patch in the refreshed nixpkgs cannot break the build.
- Confirm both evaluated configurations still build from the updated lockfile.

**Non-Goals:**

- Changing release branches, `flake.nix` input URLs, `system.stateVersion`, or `home.stateVersion`.
- Updating `nixpkgs-2511` (retained for the MySQL 8.0 overlay), `nixpkgs-unstable`, Nixvim, or other unrelated inputs.
- Bumping the `phps` input. Its current revision works once 8.1 is gone, and a bump would pull unrelated PHP changes.
- Moving PHP 8.2 projects to 8.3; that is separate follow-up work.
- Activating or testing a system generation.

## Decisions

- Use a selective lock update for the root `nixpkgs` and `home-manager` inputs, rather than the repository's `make update` target, which updates every flake input. Keep the existing branch declarations and the Home Manager `follows` relationship unchanged.
- Keep the release line at 26.05. Do not move to 26.11 before it is stable.
- Remove PHP 8.1 rather than patching the failing `filter` extension. nix-phps upstream guards that patch with `lib.versionAtLeast prev.php.version "8.2"`; 8.1 support is dropped, and no project uses 8.1, so deleting the 8.1 references is smaller than carrying an overlay workaround plus a `phps` bump.
- Keep the `phps` overlay and the `php82`/`php83` overrides untouched; 8.2 keeps coming from `phps` so the LAMP stack is unchanged apart from the dropped 8.1 entry.
- Validate the resulting lockfile against both outputs with `make os-build` and `make home-build`. These targets build only; activation remains a human decision.
- Review the lockfile diff to ensure the requested inputs are refreshed and unrelated inputs and state-version settings remain unchanged.

## Risks / Trade-offs

- New nixpkgs revisions can change packages or invalidate NixOS/Home Manager options. Build both configurations before considering the update complete; build success does not prove runtime behavior.
- Removing PHP 8.1 deletes `php81`/`composer81` from the system profile and the `php81.vm.local` site. Shell history or project `.envrc` files that call those binaries fail until updated; no remaining project is on 8.1 by the user's statement.
- An accidental update to `nixpkgs-2511` can affect the MySQL 8.0 compatibility overlay. Keep it out of the selected-input update and verify its lock entry is unchanged.

## Migration Plan

No state migration is planned. If either build fails or the result is unsuitable, revert the `flake.lock` changes; do not activate the new configuration as part of this change.
