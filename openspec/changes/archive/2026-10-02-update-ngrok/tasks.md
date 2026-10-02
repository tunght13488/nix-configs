# Tasks

## 1. Switch ngrok package to nixos-unstable

- [x] 1.1 In `home-manager/ngrok.nix`, add `package = pkgs.unstable.ngrok;`
      to the `programs.ngrok` block (verify: `nix eval
      .#homeConfigurations.'"tung@nixos-vmware"'.config.programs.ngrok.package.version`
      — observed `"3.39.5"`, not `"3.31.0"`; the `3.39.10` first written
      here was the unpinned nixos-unstable tip, the repo's
      `nixpkgs-unstable` pin resolves to 3.39.5)
- [x] 1.2 Run `make home-build` and verify it succeeds — this rebuilds
      `staticConfig`, so `ngrok config check` from the unstable binary
      must pass against the existing endpoints/settings config (observed:
      build succeeded; `ngrok.yml.drv` built with `ngrok-3.39.5`)
- [x] 1.3 Report to the user that `make home` is ready for them to run
      (per repo rules, the agent does not run switch commands)
