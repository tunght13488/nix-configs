## 1. Flake inputs

- [ ] 1.1 In `flake.nix`: change `nixpkgs.url` from `nixos-25.11` to `nixos-26.05`
- [ ] 1.2 In `flake.nix`: change `home-manager.url` from `release-25.11` to `release-26.05` (keep `inputs.nixpkgs.follows = "nixpkgs"`)
- [ ] 1.3 In `flake.nix`: change `nixvim.url` from `nixos-25.11` to `nixos-26.05`
- [ ] 1.4 In `flake.nix`: add input `nixpkgs-mysql80.url = "github:NixOS/nixpkgs/nixos-25.11"` (no follows)
- [ ] 1.5 Update `AGENTS.md` architecture notes that mention the 25.11 release-branch pinning convention to reference 26.05

## 2. MySQL side-pin overlay

- [ ] 2.1 In `overlays/default.nix`: add `mysql80-packages` overlay exposing `mysql80 = (import inputs.nixpkgs-mysql80 { system = final.system; }).mysql80;`
- [ ] 2.2 In `flake.nix` `nixosConfigurations.nixos-vmware`: append `self.overlays.mysql80-packages` to the module overlay list (after existing overlays)
- [ ] 2.3 Confirm `nixos/mysql.nix` still references `pkgs.mysql80` unchanged

## 3. Lock update and evaluation

- [ ] 3.1 `nix flake lock --update-input nixpkgs --update-input home-manager --update-input nixvim` to add `nixpkgs-mysql80` and refresh the bumped inputs
- [ ] 3.2 `nix flake show --no-write-lock-file` evaluates cleanly
- [ ] 3.3 `make os-build` passes
- [ ] 3.4 `make home-build` passes (watch for nixvim/hm 26.05 option renames; fix fallout)
- [ ] 3.5 Verify overlay ordering guard: `modifications` still runs before `phps` in all overlay lists; the php81 override block in `modifications` is untouched

## 4. Handoff

- [ ] 4.1 Ask user to run `make os` and `make home` to apply
- [ ] 4.2 Post-switch smoke test (user): `systemctl status mysql`, `mysql -e 'SELECT VERSION();'` returns 8.0.x, php81/php82/php83.local sites respond, `mycli` connects
