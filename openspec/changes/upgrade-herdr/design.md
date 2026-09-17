## Context

The home-manager configuration consumes Herdr in two ways: `inputs.herdr.overlays.default` provides `pkgs.herdr`, and the additions overlay derives the Pi/OpenCode skill from `${inputs.herdr.outPath}/skills/herdr/SKILL.md`. `home-manager/herdr.nix` also generates a writable TOML bootstrap from the current baseline. The existing Herdr input is a tag-pinned dependency at v0.9.0 and does not follow the repository's main nixpkgs input.

See proposal.md for the motivation and the modified requirement in `specs/herdr-terminal-multiplexer/spec.md` for the contract.

## Goals / Non-Goals

**Goals:**

- Move the Herdr input and lock entry to stable v0.9.1.
- Preserve the existing package overlay, agent-skill source path, writable config behavior, and tmux coexistence.
- Validate the v0.9.1 package, generated skill files, and current config baseline before activation.
- Keep the change reversible by retaining the prior tag and lock state as the rollback point.

**Non-Goals:**

- Adding new Herdr configuration keys or changing the user's baseline theme, prefix, toast, or panel settings.
- Changing tmux configuration or introducing a second Herdr packaging mechanism.
- Enabling or configuring saved remote machines, Windows hosts, or other v0.9.1 features.
- Updating unrelated flake inputs.

## Decisions

- **Use the v0.9.1 release tag and a targeted lock update.** Change only the Herdr URL and run `nix flake lock --update-input herdr`, allowing the lock file to record the release revision and the transitive dependencies required by that input. Do not use a branch, floating revision, or `nix flake update`, which could introduce unrelated dependency changes. Do not add a `follows` override because the existing integration intentionally builds Herdr with its own nixpkgs.

- **Keep the existing integration wiring unless compatibility checks prove it must change.** The v0.9.1 package still exposes the Nix package through its flake and retains the `nix/package.nix` and `skills/herdr/SKILL.md` source paths. Therefore the current overlay and `pkgs/herdrAgentFiles` derivation remain the compatibility boundary instead of copying or vendoring the upstream skill. If an upstream path or output changes, make the smallest corresponding wiring change and record it during implementation.

- **Treat upstream validation as a release-gate, not as a new configuration feature.** Build the home-manager configuration and Herdr skill output, then run the v0.9.1 binary's config validation against the generated baseline. Preserve the writable-file behavior and check the live file separately after activation, because user edits may intentionally differ from the version-controlled baseline. Only repair a rejected existing setting; do not add optional v0.9.1 settings during this upgrade.

- **Use build-only verification before activation.** Follow the repository's verification boundary with `make home-build` and targeted package/skill checks. The activation step remains a user action, after which `herdr --version`, config validation, and the two skill links confirm the deployed result.

## Risks / Trade-offs

- [The Herdr package or its updated Rust/Zig dependency closure fails to build] → Run the home-manager build before activation; if it cannot be repaired without unrelated packaging work, restore the v0.9.0 URL and lock entry and report the upstream build issue.
- [v0.9.1 rejects an existing baseline config key] → Validate the generated TOML with the new binary and apply only a minimal compatibility correction, then repeat the build and validation checks.
- [The existing writable `~/.config/herdr/config.toml` contains stale experimental keys] → Back up or inspect the live file separately; do not overwrite a real edited file during activation. Treat failures caused only by live edits as a migration concern rather than changing the declarative baseline.
- [The upstream skill path or package output changes] → Inspect the v0.9.1 source and build `herdrAgentFiles`; update the derivation only if the existing paths no longer exist, and verify both agent-specific output paths.
- [The lock command updates unrelated inputs] → Review the lock diff and keep only changes caused by the targeted Herdr update.

## Migration Plan

1. Change the Herdr input tag and update only its lock entry.
2. Build the home-manager configuration and the Herdr agent-files output; validate the generated config with the v0.9.1 binary.
3. Review the lock and source-path diffs, then run the repository's permitted build verification.
4. Have the user run `home-manager switch` when ready to activate the new generation.
5. Verify the deployed version, live config, PATH availability, and both Pi/OpenCode skill links.
6. If activation or runtime validation fails, revert the input to v0.9.0, restore the corresponding lock state, rebuild, and keep the prior generation active.
