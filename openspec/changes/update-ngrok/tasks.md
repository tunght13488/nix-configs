# Tasks

## 1. Switch ngrok package to nixos-unstable

- [ ] 1.1 In `home-manager/ngrok.nix`, add `package = pkgs.unstable.ngrok;`
      to the `programs.ngrok` block (verify: `nix eval
      .#homeConfigurations.'"tung@nixos-vmware"'.config.programs.ngrok.package.version`
      prints `"3.39.10"`, not `"3.31.0"`)
- [ ] 1.2 Run `make home-build` and verify it succeeds — this rebuilds
      `staticConfig`, so `ngrok config check` from the unstable binary
      must pass against the existing endpoints/settings config
- [ ] 1.3 Report to the user that `make home` is ready for them to run
      (per repo rules, the agent does not run switch commands)
