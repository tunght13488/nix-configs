## Context

Postman is already declared in `home-manager/home.nix` as `unstable.postman` inside the `home.packages = with pkgs; [ ... ]` block (changed from the 25.11 `postman` attribute in commit `50bb24d`, "feat: update postman", 2026-06-29). It resolves through the `unstable-packages` overlay (`overlays/default.nix`), which exposes `pkgs.unstable` from the `nixpkgs-unstable` flake input.

The pinned `nixpkgs-unstable` input is fresh — rev `624af665418d3c65d544145b4d34ad696439570e`, `lastModified` 1785090369 (2026-07-27, one day old) — and resolves `unstable.postman.version` to **11.94.0**. That is also the version on `nixos-unstable` HEAD today (`pkgs/by-name/po/postman/package.nix` still declares `version = "11.94.0"`). There is no nixpkgs PR targeting a 12.x bump; the most recent bump commits land incremental 11.x steps (`11.87.4 -> 11.88.3` in #499965). Upstream Postman desktop is at **12.20.4** (Chocolatey, approved 2026-07-25; the `dl.pstmn.io/download/version/12.20.4/linux64` endpoint serves a ~160 MB tarball, confirmed reachable).

So unlike `jetbrains-toolbox` (where bumping the unstable input alone reached a current build because nixpkgs HEAD already carried the new version), bumping the lock here yields **no Postman update at all** — the nixpkgs package itself is the bottleneck. The mechanism nixpkgs uses is a simple `fetchurl` from `https://dl.pstmn.io/download/version/${version}/${system}` with a per-system SRI hash, so an `overrideAttrs` that repins `version` + `src` reuses all of the upstream build/wrap logic while swapping in the 12.20.4 binary.

The repo already establishes the override precedent in exactly this place: the same `.extend (...)` block pins `unstable.openspec` to a specific GitHub tag via `overrideAttrs`. This change reuses that pattern.

## Goals / Non-Goals

**Goals:**
- Deliver a current Postman desktop build (12.20.4, the latest upstream release) on this machine while remaining on the `unstable` channel, by pinning `unstable.postman` to the latest upstream version via an `overrideAttrs` override layered on the existing nixpkgs `postman` derivation.
- Keep the diff minimal: edit `overlays/default.nix` only. Touch neither `home-manager/home.nix` (already on `unstable.postman`) nor `flake.lock`.
- Verify with `make home-build` and a version eval, per repo AGENTS.md (AI agents run `make home-build` only, never `make home`).

**Non-Goals:**
- Making nixpkgs ship a newer `postman`. That is an upstream concern; this change works around the lag at the repo level.
- Eliminating re-bump recurrence. Each future upstream Postman release will require re-pinning the version + hash in the overlay. Accepted tradeoff of choosing an explicit pin.
- Multi-arch correctness. The flake targets a single machine (`nixos-vmware`, x86_64-linux); only the `linux64` source hash is filled.
- Patching Postman's runtime behavior (e.g. nixpkgs issue #504180, "No GSettings schemas are installed", which affects 11.94.0 already). Out of scope; independent of the version bump.
- Bumping `nixpkgs-unstable` or any other flake input as part of this change (see Decision 5).

## Decisions

### Decision 1: Pin via `overrideAttrs` on `unstable.postman` (an upstream version pin), not a flake-lock bump
**Choice:** Layer an `overrideAttrs` override on `prev'.postman` inside the `unstable-packages` overlay that repins `version` and `src` to the latest upstream Postman (12.20.4), keeping the nixpkgs build/wrap phases underneath.

**Rationale:** The nixpkgs `postman` package is at 11.94.0 on both the pinned unstable input and `nixos-unstable` HEAD, and no PR targets 12.x. Bumping the lock alone produces zero Postman version movement — confirmed by eval against the current flake and by inspecting the `package.nix` on the `nixos-unstable` branch. This is the inverse conclusion from the `jetbrains-toolbox` change, and the difference is grounded in fact: Toolbox reached current via a lock bump only because nixpkgs HEAD already carried `3.6.2.85969`; Postman does not.

**Alternatives considered:**
- **Option 1a (full `make update` / `nix flake update`):** Rejected. Drags every 25.11-release-branch input forward, defeating the release-branch pinning philosophy, and — critically — does not move Postman off 11.94.0 because the upstream nixpkgs package itself is at 11.94.0.
- **Option 1b (targeted `nix flake update --input nixpkgs-unstable`):** Rejected for the same reason — no Postman version gain — and as unnecessary churn.
- **Option 3 (custom `pkgs/postman-latest.nix` derivation, fully standalone):** Rejected. Duplicates the nixpkgs Electron-wrap/install logic and is fragile to upstream tarball structural changes; the `overrideAttrs` approach inherits that logic instead.
- **Option 4 (switch to a NUR / community `postman-bin` that already tracks 12.x):** Rejected. Introduces a new flake input (NUR) and violates the repo's minimal-input / 25.11-branch discipline.
- **Option 5 (wait for nixpkgs to ship 12.x, do nothing):** Rejected. Indefinite; the user wants a current build now.

### Decision 2: Locate the override inside the `unstable-packages` overlay's `.extend (...)` block, not in `modifications`
**Choice:** Add `postman = prev'.postman.overrideAttrs ...` inside the existing `final'.extend (final': prev': { ... })` block of the `unstable-packages` overlay, beside the current `openspec` override.

**Rationale:** `home.nix` consumes `unstable.postman` specifically, so the override must land on the `unstable` set, not the 25.11 `pkgs.postman` (which nothing references). Scoping it to the `.extend` block in `unstable-packages` matches the established `openspec` precedent exactly and leaves the 25.11 `postman` attribute untouched.

**Alternatives considered:**
- **`modifications` overlay over `prev.postman`:** Wrong target — would override the unused 25.11 derivation and leave `unstable.postman` still at 11.94.0. Rejected.

### Decision 3: Pin to a concrete upstream version (12.20.4), not resolve "latest" dynamically
**Choice:** Hard-code `version = "12.20.4"` and the matching `linux64` SRI hash in the override.

**Rationale:** Nix fixed-output derivations need a known hash, and `dl.pstmn.io/download/version/latest/linux64` returns **HTTP 404** (confirmed via `curl -sIL`) — there is no versioned-latest redirect to lean on. A specific version string + its hash is the only reproducible path. This is also why Option 1 (no pin) cannot work for Postman even in theory.

**Alternatives considered:**
- **Script that resolves the latest version at build time:** Rejected. Non-reproducible, non-declarative, and hostile to `nix flake check`.

### Decision 4: Fill only the `linux64` source hash
**Choice:** In the override's `src`, provide only the x86_64-linux (`linux64`) fetchurl/hash.

**Rationale:** The flake targets exactly one system (`nixos-vmware`, x86_64-linux). Reproducing the macOS/Darwin hashes from a Linux host is impractical (different stdenv), and those systems are never evaluated here.

**Alternatives considered:**
- **Fill all four per-system hashes:** Rejected. Unverifiable from this host and unnecessary; the existing single-system scope of the flake makes the trade-off acceptable. (Documented as a known limitation in the proposal/spec.)

### Decision 5: No `flake.lock` change in this change
**Choice:** Leave `flake.lock` byte-identical; the override fetches the upstream binary directly via a fixed-output fetchurl that does not touch the lock.

**Rationale:** The version pin does not depend on the unstable rev for the *version number* (we override it) — it only inherits the build/wrap logic, which the current one-day-old rev already supplies correctly. Bumping would churn unrelated `unstable.*` consumers (`zed-editor`, `uv`, `openspec`, `jetbrains-toolbox`) with no Postman benefit. Keeping the diff to `overlays/default.nix` is the cleanest change.

**Alternatives considered:**
- **Also run `nix flake update --input nixpkgs-unstable` "for hygiene":** Rejected as unnecessary churn in this change; can be a separate change if desired.

## Risks / Trade-offs

- **[Major-version structural drift (11.94.0 -> 12.20.4)]** The inherited nixpkgs `installPhase`/`wrapProgram` was authored against 11.x tarball layout. If 12.20.4 restructures the archive, `make home-build` will fail. → Mitigation: surface at build; if it fails, extend the override to also adjust `buildInputs`/`installPhase`/`wrapProgram` flags for 12.x; documented as a fallback task step. Postman's Electron tarball layout has been stable across many major versions historically (9.x -> 11.x), so this risk is moderated.
- **[Runtime quirks at 12.x]** nixpkgs issue #504180 ("No GSettings schemas are installed") already affects 11.94.0 and is independent of the bump; new 12.x runtime quirks are possible. → Mitigation: runtime launch test after the user runs `make home`; treat any new runtime breakage as a separate change.
- **[Manual re-bump on every upstream release]** Accepted tradeoff of pinning; the override + tasks document the prefetch procedure so the next bump is mechanical.
- **[Pin rides on the underlying `unstable.postman` package.nix shape]** Future `nixpkgs-unstable` bumps could change the wrap logic and break the override. → Mitigation: `make home-build` verifies; the override sets only `version` + `src`, so most package.nix edits are transparent.
- **[x86_64-linux only]** Other systems would throw at eval because only the `linux64` hash is filled. → Accepted; the flake targets a single machine.

## Migration Plan

1. Confirm the latest upstream Postman desktop version (target **12.20.4**; verify at implementation time against the Postman release notes and `HEAD` against `https://dl.pstmn.io/download/version/<ver>/linux64`).
2. Prefetch the Linux64 tarball hash: `nix-prefetch-url --type sha256 https://dl.pstmn.io/download/version/12.20.4/linux64` (the nixpkgs `postman` package uses `fetchurl` over the compressed `.tar.gz`, so hash over the archive, no `--unpack`), then `nix hash to-sri --type sha256 <nix-base32>`.
3. Edit `overlays/default.nix`: inside the `unstable-packages` overlay's `final'.extend (final': prev': { ... })` block add a `postman = prev'.postman.overrideAttrs (old: { version = "12.20.4"; src = final'.fetchurl { name = "postman-12.20.4.tar.gz"; url = "https://dl.pstmn.io/download/version/12.20.4/linux64"; hash = "<sri>"; }; });` entry, keeping the existing `openspec` override alongside.
4. `make format` (nixpkgs-fmt).
5. `make home-build` to verify evaluation builds the new derivation. If it fails on structural drift, fall back per Risk 1.
6. Confirm: `nix eval --raw '.#nixosConfigurations.nixos-vmware.pkgs.unstable.postman.version'` prints `12.20.4`.
7. (User-run) `make home` to apply — AI agents MUST NOT run this per AGENTS.md.
8. Runtime verify: launch Postman; Help/About reports 12.20.4.

**Rollback:** `git revert` the single `overlays/default.nix` edit. `home-manager/home.nix` and `flake.lock` are untouched, so revert is trivial and incurs no lock dance.

## Open Questions

- Does 12.20.4 build cleanly on top of the inherited 11.94.0 `package.nix` wrap logic, or does the override need to also supply `buildInputs`/`installPhase` adjustments? Answered empirically at step 5 (`make home-build`). If it fails, the fallback task step applies the minimal structural override required.
- Should a separate cleanup change bump `nixpkgs-unstable` for general hygiene? Out of scope here (Decision 5); raise as its own change if desired.