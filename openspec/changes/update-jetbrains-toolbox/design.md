## Context

`jetbrains-toolbox` is currently declared in `home-manager/home.nix` as `jetbrains-toolbox` inside a `home.packages = with pkgs; [ ... ]` block, which resolves to the `nixos-25.11` nixpkgs input — version **3.1.0.62320**. The nixpkgs-25.11 release branch will not bump Toolbox (only security backports), so this version is frozen for the branch lifetime.

Upstream is at **3.6.2.85969** (nixpkgs PR #542679, merged 2026-07-16 on `nixpkgs-unstable`). The currently pinned `nixpkgs-unstable` flake input resolves Toolbox to **3.5.0.84344** — newer than 25.11 but itself behind upstream, so a flake.lock bump is also required to reach current.

The repo already establishes a convention for bleeding-edge packages: an `unstable-packages` overlay (`overlays/default.nix`) exposes `pkgs.unstable`, and `home.nix` already pulls `unstable.postman`, `unstable.zed-editor`, `unstable.uv`, `unstable.openspec` from it. This change extends that exact pattern to Toolbox.

The running Toolbox process was observed launching with `--update-failed` (visible in `pgrep -fa toolbox`). This is expected: the binary lives in the read-only `/nix/store` and cannot self-update in place. The IDEs it manages are unaffected — they live in `~/.local/share/JetBrains/Toolbox/apps/{intellij-idea,phpstorm,webstorm,air}` and are updated by Toolbox into the writable home tree, which is out of scope.

## Goals / Non-Goals

**Goals:**
- Move `jetbrains-toolbox` from the frozen 25.11 attribute to the unstable channel so the home-manager build tracks upstream's cadence.
- Reach a current upstream Toolbox build (3.6.x) on this machine via a targeted, low-churn flake.lock update that does not disturb the 25.11 release-branch inputs.
- Verify the change with `make home-build` and a runtime `--version` check, per repo AGENTS.md (AI agents run `make home-build` only, never `make home`).

**Non-Goals:**
- Making Toolbox self-update work in place (would require an out-of-nix install — Option 3, deliberately not chosen).
- Suppressing the `--update-failed` flag. It may persist after the bump; it is cosmetic noise, not a functional failure.
- Changing how JetBrains IDEs are installed/updated (they stay Toolbox-managed under `~/.local/share`).
- Pinning Toolbox to a specific rev via an overlay overrideAttrs (Option 2, not chosen). Option 1 defers version selection to whatever `nixpkgs-unstable` resolves to at bump time, which is acceptable for a launcher binary.
- Full `nix flake update` (all inputs). Only `nixpkgs-unstable` is bumped.

## Decisions

### Decision 1: Use `unstable.jetbrains-toolbox` rather than a 25.11 overlay override
**Choice:** Swap the `home.nix` package entry to `unstable.jetbrains-toolbox` (flat attribute — confirmed `pkgs.jetbrains.jetbrains-toolbox` is `MISSING` on unstable; `unstable.jetbrains-toolbox` resolves to `3.5.0.84344` pre-bump).

**Rationale:** Matches the existing `unstable.*` convention already used for four other packages. Zero new machinery, fully reversible, no overlay authoring or hash maintenance.

**Alternatives considered:**
- **Option 2 (overlay `overrideAttrs` pinning a specific upstream rev):** More explicit and reproducible, but requires hand-maintaining the upstream src URL + hash on every bump. Overkill for a launcher binary whose regression is low-impact. Rejected.
- **Option 3 (out-of-nix, self-managing Toolbox):** Eliminates drift permanently and matches Toolbox's designed update model, but breaks the repo's declarative principle and loses rollback on the launcher. Rejected for now; revisit only if bump recurrence becomes annoying.

### Decision 2: Targeted `--input nixpkgs-unstable` bump rather than full `nix flake update`
**Choice:** `nix flake update --input nixpkgs-unstable`.

**Rationale:** The repo's philosophy is 25.11 release-branch stability with unstable as a controlled escape hatch. A targeted bump advances only the escape-hatch input and leaves `home-manager`, `nixvim`, `agenix`, `nix-index-database`, `phps`, and the 25.11 nixpkgs on their pinned release branches. Lower churn, lower risk, semantically honest.

**Alternatives considered:**
- **`make update` (full `nix flake update`):** Would also reach 3.6.2 but drags every release-branch input forward, defeating the release-branch pinning philosophy. Rejected.

### Decision 3: Attribute path is flat `unstable.jetbrains-toolbox`, not nested
**Choice:** Reference `unstable.jetbrains-toolbox` in the `with pkgs;` list.

**Rationale:** Eval confirmed the nested `pkgs.jetbrains.jetbrains-toolbox` attribute is `MISSING` on the unstable flake input (Toolbox moved to `pkgs/by-name/je/jetbrains-toolbox`, which exposes it at the top level). Using the nested path would silently fail to evaluate.

## Risks / Trade-offs

- **[Drift recurs]** Every new upstream Toolbox release leaves us behind until the next `nix flake update --input nixpkgs-unstable`. → Accepted tradeoff of Option 1. If recurrence becomes annoying, escalate to Option 3 (out-of-nix self-managing install).
- **[`--update-failed` may persist]** Toolbox 3.6's changelog (storage cleanup, Windows diagnostics) says nothing about NixOS self-update behavior. The flag may continue to fire because the binary still can't write to `/nix/store`. → Treat as cosmetic noise. If it becomes actively problematic, that is a separate change (patch to suppress, or Option 3).
- **[Unstable carries other changes]** Bumping `nixpkgs-unstable` advances more than just Toolbox; any other `unstable.*` consumers (`postman`, `zed-editor`, `uv`, `openspec`) ride along. → Intended behavior of the escape-hatch input; reviewable in the `flake.lock` diff before commit.
- **[Attribute path sensitivity]** If a future nixpkgs refactor moves Toolbox off the top-level `by-name` attribute, `unstable.jetbrains-toolbox` would break at eval time. → Detectable at `make home-build` (eval failure), not a silent runtime issue.

## Migration Plan

1. Edit `home-manager/home.nix`: replace `jetbrains-toolbox` with `unstable.jetbrains-toolbox` in the `home.packages = with pkgs; [ ... ]` block.
2. `nix flake update --input nixpkgs-unstable`.
3. `make home-build` to verify evaluation/build.
4. (User-run) `make home` to apply — AI agents must NOT run this per AGENTS.md.
5. Verify runtime: `which jetbrains-toolbox` resolves to a `*-jetbrains-toolbox-3.6.x.*` store path; `jetbrains-toolbox --version` prints the new version.

**Rollback:** `git revert` the `home.nix` one-liner and restore the prior `nixpkgs-unstable` node in `flake.lock` (or `nix flake update --input nixpkgs-unstable --revision <old>`). No data migration; IDEs in `~/.local/share` are untouched.

## Open Questions

- None blocking. The only soft unknown is whether `--update-failed` actually disappears at 3.6.2; it does not gate this change either way.