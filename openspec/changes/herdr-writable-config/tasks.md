## 1. Implementation

- [ ] 1.1 Replace `xdg.configFile."herdr/config.toml"` with `home.activation.copyHerdrConfig` in `home-manager/herdr.nix`
- [ ] 1.2 Add guard conditions: copy only if file missing or is a symlink, otherwise leave alone
- [ ] 1.3 Order activation after `writeBoundary` using `lib.hm.dag.entryAfter`
- [ ] 1.4 Add module comment documenting the copy-once behavior and manual reset steps
- [ ] 1.5 Verify with `make home-build`
