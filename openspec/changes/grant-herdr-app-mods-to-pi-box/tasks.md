# Tasks

## 1. Grant Herdr mods access in the shared pi-box profile

- [ ] 1.1 Add `${homeDir}/.config/herdr-app/mods` to the shared base profile's `filesystem.allow` list in `home-manager/pi-sandbox.nix`; verify `make home-build` succeeds and the evaluated profile grants this exact path rather than the parent directory.
- [ ] 1.2 After a human applies the Home Manager generation, run `nono profile validate pi-box` and verify a default pi-box session can read mods and create, read, and update a disposable file in `~/.config/herdr-app/mods`, with changes visible on the host.
