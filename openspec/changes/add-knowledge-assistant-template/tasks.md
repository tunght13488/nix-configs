# Tasks

## 1. Template image and package validation

- [ ] 1.1 Add `home-manager/pi-box-templates/knowledge-assistant/Dockerfile.pi` on `pi-sandbox` and install `@sysid/mmdlint@0.1.1`; force-add the globally ignored Dockerfile and verify it is tracked with `git ls-files --error-unmatch`.
- [ ] 1.2 Build the template image and run `mmdlint` against valid and invalid Mermaid Markdown fixtures in `.tmp`; verify the valid document exits successfully and the invalid document exits non-zero.

## 2. Template catalog documentation

- [ ] 2.1 Add the `knowledge-assistant` template and its Mermaid-linting purpose to the template catalog in `AGENTS.md`; verify the entry and `pi-box init knowledge-assistant` command with `rg`.

## 3. Home Manager integration

- [ ] 3.1 Run `make home-build` and verify the Home Manager generation builds with the new recursively deployed template source.
- [ ] 3.2 After the user applies Home Manager with `make home`, verify `~/.pi/sandbox/templates/knowledge-assistant/Dockerfile.pi` is deployed and `pi-box init knowledge-assistant` in a disposable `.tmp` workspace creates the template Dockerfile and generic manifest without extra grants.
