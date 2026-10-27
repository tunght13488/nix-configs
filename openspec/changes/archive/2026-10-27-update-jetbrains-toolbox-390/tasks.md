# Tasks

## 1. Pin the package

- [x] 1.1 Add `pkgs/jetbrains-toolbox.nix` with `version = "3.9.0.88839"`, the `download.jetbrains.com` URL, and the `x86_64-linux` fetchzip hash; verify `nix eval --raw --expr` on the file returns `3.9.0.88839`.
- [x] 1.2 Wire it into the `unstable-packages` overlay as `unstable.jetbrains-toolbox` via `final'.callPackage`, and verify `nix eval` reports version `3.9.0.88839` for the extended set while `unstable.postman` keeps its 12.20.4 pin.

## 2. Verify the build

- [x] 2.1 Run `make home-build` and verify it builds `jetbrains-toolbox-3.9.0.88839` from `download.jetbrains.com` without touching a cached copy.
- [x] 2.2 Verify `flake.lock` is byte-identical to before the change and that `git status` shows only the new package file, the overlay entry, and this change's artifacts.

## 3. Close the loop on the blocked verification

- [x] 3.1 Re-run `make home-build` inside the pi-box sandbox (`add-nix-configs-pi-box-template` task 3.2) and record whether it now completes, then drop the record of the Toolbox 404 from that change's follow-up notes.

## Workflow follow-up

- `jetbrains-toolbox --version` prints `Toolbox 3.9.0.88839` from the built FHS wrapper.
- The fetchzip hash must come from a prefetch tree hash, not the tarball's `.sha256`; the first attempt used the file hash and failed with a hash mismatch.
- Delete `pkgs/jetbrains-toolbox.nix` and its overlay entry once `nixpkgs-unstable` ships 3.9.0 or newer from `download.jetbrains.com`.
- Archive this change once reviewed.
