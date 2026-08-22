## 1. Flake inputs

- [x] 1.1 In `flake.nix`: change `nixpkgs.url` from `nixos-25.11` to `nixos-26.05`
- [x] 1.2 In `flake.nix`: change `home-manager.url` from `release-25.11` to `release-26.05` (keep `inputs.nixpkgs.follows = "nixpkgs"`)
- [x] 1.3 In `flake.nix`: change `nixvim.url` from `nixos-25.11` to `nixos-26.05`
- [x] 1.4 In `flake.nix`: add input `nixpkgs-2511.url = "github:NixOS/nixpkgs/nixos-25.11"` (no follows)
- [x] 1.5 Update `AGENTS.md` architecture notes that mention the 25.11 release-branch pinning convention to reference 26.05

## 2. MySQL side-pin overlay

- [x] 2.1 In `overlays/default.nix`: add `mysql80-packages` overlay exposing `mysql80 = (import inputs.nixpkgs-2511 { system = final.system; }).mysql80;`
- [x] 2.2 In `nixos/configuration.nix` (where the NixOS overlay list lives): append `inputs.self.overlays.mysql80-packages` to the overlay list (after existing overlays)
- [x] 2.3 Confirm `nixos/mysql.nix` still references `pkgs.mysql80` unchanged

## 3. Lock update and evaluation

- [x] 3.1 `nix flake lock --update-input nixpkgs --update-input home-manager --update-input nixvim` to add `nixpkgs-2511` and refresh the bumped inputs
- [x] 3.2 `nix flake show --no-write-lock-file` evaluates cleanly
- [x] 3.3 `make os-build` passes
- [x] 3.4 `make home-build` passes (watch for nixvim/hm 26.05 option renames; fix fallout)
- [x] 3.5 Verify overlay ordering guard: `modifications` still runs before `phps` in all overlay lists; the php81 override block in `modifications` is untouched

## 4. Handoff

- [x] 4.1 Add `make os-boot` target and ask user to stage with boot-first for this major upgrade: `make os-boot`, then reboot, verify desktop boots to GDM, then `make home` (fallback if GDM fails at boot: GRUB → previous generation; see design.md Migration Plan)
- [x] 4.2 Post-switch smoke test (user): `systemctl status mysql`, `mysql -e 'SELECT VERSION();'` returns 8.0.x, php81/php82/php83.local sites respond, `mycli` connects, nvim treesitter highlighting works (nixvim 26.05 removed per-grammar packages in the diff)
