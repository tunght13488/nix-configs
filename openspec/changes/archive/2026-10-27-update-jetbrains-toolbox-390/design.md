# Design

## Context

See `proposal.md` for motivation. The pinned `nixpkgs-unstable` revision (`/nix/store/aiapnjc6w07cz0jxy8s3j8cg1vfh1k8b-source`) defines `jetbrains-toolbox` 3.6.2.85969 as a `buildFHSEnv` whose source comes from `sourceForVersion version`, a `let`-bound helper. Both `version` and the resulting source are therefore closed over at call time: the finished derivation exposes the source only as `passthru.src`, and the FHS environment that consumes it is already built.

Measured state of the download hosts:

| Revision | Version | Host | HTTP |
|---|---|---|---|
| pinned `nixpkgs-unstable` | 3.6.2.85969 | `download-cdn.jetbrains.com` | 404 |
| current `nixos-unstable` | 3.8.1.88030 | `download.jetbrains.com` | 302 |
| `master` | 3.9.0.88839 | `download.jetbrains.com` | 302 |

`download-cdn` also 404s 3.8.1, so the host change - not the version - is what breaks the pinned revision.

## Goals / Non-Goals

**Goals:**
- Ship 3.9.0.88839 from a host that serves it, without advancing any flake input.
- Keep the consumed attribute name `unstable.jetbrains-toolbox` so `home-manager/home.nix` is untouched.

**Non-Goals:**
- Bumping `nixpkgs-unstable` (that yields 3.8.1.88030 and moves every other unstable package).
- Extending the package to `aarch64` or darwin; this repository builds `x86_64-linux` only.
- Managing JetBrains IDEs, which stay Toolbox-managed under `~/.local/share/JetBrains/Toolbox/apps/`.

## Decisions

### Re-instantiate the derivation instead of overriding it

`overrideAttrs` cannot express this bump: `version` is a `let` binding in nixpkgs' package file, and the FHS environment consumes the source at call time, so `src = ...` in an override would be inert. The repository therefore owns a linux-only copy of the derivation in `pkgs/jetbrains-toolbox.nix`, following `pkgs/obsidian.nix` (upstream binary pinned in-repo with update notes) and the `postman` overlay override (unstable lags upstream).

The copy keeps nixpkgs' shape - `fetchzip` source, `buildFHSEnv` with `appimageTools.defaultFhsEnvArgs.multiPkgs`, `runScript` using `--update-failed`, desktop file and tray icon install - so behavior matches the replaced package. Dropping the darwin branch is safe because the flake's darwin outputs are not used by this configuration.

### Wire it through the existing unstable overlay

`overlays/default.nix` already imports `nixpkgs-unstable` and extends it for `postman`; `jetbrains-toolbox` joins the same `extend` block, resolved with `final'.callPackage` so its dependencies come from the unstable set rather than 26.05. It is deliberately not added to `pkgs/default.nix`: that file feeds the `additions` overlay for the stable package set, and a second wiring point would create an unused duplicate attribute.

### Update procedure

Bumping later means editing `version` plus the `x86_64-linux` hash in one file:

```bash
nix store prefetch-file --hash-type sha256 \
  "https://download.jetbrains.com/toolbox/jetbrains-toolbox-<version>.tar.gz"
```

The hash must be a `fetchzip` tree hash (unpacked archive), not the tarball's own `.sha256` - the two differ, so take the value from the prefetch result or from the corresponding nixpkgs revision.

## Risks / Trade-offs

- [A pinned version can rot again when JetBrains drops it] -> The update procedure is documented in the file header; `nixpkgs` carries the same exposure, and its fix is what this change backports.
- [The in-repo derivation can drift from nixpkgs' package definition] -> It is a deliberate near-copy; the header states where it came from, and the next `nixpkgs-unstable` bump should delete the override once unstable ships 3.9.0 or newer.
- [`buildFHSEnv` needs a 155 MB download per fresh store and is unfree] -> Already the case for the replaced package; `unstable` sets `allowUnfree = true`.
- [Only `x86_64-linux` is defined] -> Intentional; evaluation on other systems fails loudly rather than silently building the wrong source.
