## 1. Confirm upstream target version and prefetch source hash

- [x] 1.1 Confirm the latest upstream Postman desktop version (target **12.20.4**); verify it is currently the latest via the Postman app release notes and that `curl -sIL https://dl.pstmn.io/download/version/12.20.4/linux64` returns HTTP 200 with the expected tarball content-length (~160 MB)
- [x] 1.2 Prefetch the Linux64 tarball: `nix-prefetch-url --type sha256 https://dl.pstmn.io/download/version/12.20.4/linux64` (nixpkgs `postman` uses `fetchurl` over the compressed `.tar.gz` — hash is over the archive, no `--unpack`)
- [x] 1.3 Convert to SRI: `nix hash to-sri --type sha256 <nix-base32-from-step-1.2>`; record the SRI hash for the override
- [x] 1.4 Sanity-check `nix eval --raw '.#nixosConfigurations.nixos-vmware.pkgs.unstable.postman.version'` currently prints `11.94.0` (baseline before the override)

## 2. Add the `unstable.postman` override in `overlays/default.nix`

- [x] 2.1 Inside the `unstable-packages` overlay's `final'.extend (final': prev': { ... })` block in `overlays/default.nix`, add `postman = prev'.postman.overrideAttrs (old: { version = "12.20.4"; src = final'.fetchurl { name = "postman-12.20.4.tar.gz"; url = "https://dl.pstmn.io/download/version/12.20.4/linux64"; hash = "<sri-from-1.3>"; }; });` next to the existing `openspec` override
- [x] 2.2 Leave `home-manager/home.nix` and `flake.lock` unchanged (the entry already references `unstable.postman`; satisfies spec scenarios "No change to the home-manager package entry is required" and "Only overlays/default.nix changes")
- [x] 2.3 Run `make format` (nixpkgs-fmt) on the edited `overlays/default.nix`
- [x] 2.4 `git add` the edited file if nixpkgs-fmt/i-remove introduces any new files (none expected; per AGENTS.md, new files must be `git add`ed before nix evaluation can import them)

## 3. Structural-drift fallback (only if step 3.1 build fails)

- [x] 3.0 (conditional, not triggered) If `make home-build` in step 4.1 fails because the 11.94.0-era `installPhase`/`wrapProgram` does not fit the 12.20.4 tarball layout, extend the `overrideAttrs` to also override the minimal fields needed (e.g. `buildInputs`, `installPhase`, or `wrapProgram` args) so 12.20.4 builds; keep the override as small as possible
- [x] 3.1 (conditional, not triggered) If structural fixes prove extensive, fall back to the latest still-compatible upstream version and record the actual pinned version in proposal.md/spec deltas; only as a last resort, abandon the pin and raise "wait for nixpkgs 12.x" as a separate change

## 4. Verification (eval/build only — AI agents MUST NOT run `make home`)

- [x] 4.1 Run `make home-build` and confirm the home-manager configuration evaluates and builds without errors (surface any structural-drift failure here, triggering section 3)
- [x] 4.2 Confirm `nix eval --raw '.#nixosConfigurations.nixos-vmware.pkgs.unstable.postman.version'` now prints `12.20.4` (satisfies spec scenario "The unstable postman derivation reports the pinned upstream version")
- [x] 4.3 `nix flake check --no-write-lock-file` (or deeper eval) passes without referencing the `nixos-25.11` `postman` attribute

## 5. Spec-scenario cross-check

- [x] 5.1 Verify spec scenario "Package entry resolves to the unstable input": `home-manager/home.nix` still lists `unstable.postman` (unchanged) and the build references the unstable overlay, not the 25.11 `postman` attribute
- [x] 5.2 Verify spec scenario "The source is fetched from the upstream versioned download endpoint": the override's `src.url` is `https://dl.pstmn.io/download/version/12.20.4/linux64` with the matching SRI hash
- [x] 5.3 Verify spec scenario "Only overlays/default.nix changes": `git diff --stat` shows exactly one modified file (`overlays/default.nix`); `flake.lock` and all flake input nodes (`nixpkgs`, `nixpkgs-unstable`, `home-manager`, `nixvim`, `agenix`, `nix-index-database`, `phps`) are byte-identical to the prior commit
- [x] 5.4 Verify spec scenario "Other unstable consumers are unaffected": `nix eval` of `unstable.zed-editor`, `unstable.uv`, `unstable.openspec`, `unstable.jetbrains-toolbox` resolves to the same derivations as before the change

## 6. Handoff

- [x] 6.1 Commit the `overlays/default.nix` change with a clear message (no emojis per AGENTS.md) and no `flake.lock` change
- [x] 6.2 Ask the user to run `make home` to apply (AI agents do NOT run `make home` / `nixos-rebuild switch`)
- [x] 6.3 Post-apply runtime verification: launch Postman; Help/About reports version 12.20.4