# Tasks

## 1. Install dnsutils

- [ ] 1.1 Add `dnsutils` to `home.packages` in `home-manager/terminal.nix` and verify the file still parses (run `make home-build`, expect a successful build)
- [ ] 1.2 Ask the user to run `make home` to activate, then verify `command -v dig` prints a path under `/nix/store`
- [ ] 1.3 Verify `dig +short example.com` exits 0 and prints an IP address, and `myip` prints the machine's public IP

## Workflow follow-up

- Archive the change after the project's review requirements are satisfied.
- Verify the archived result.
