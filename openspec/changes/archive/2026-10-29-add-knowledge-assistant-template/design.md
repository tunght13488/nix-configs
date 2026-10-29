# Design

## Context

See `proposal.md` for the motivation and `specs/pi-box-templates/spec.md` for the behavior contract. Templates are deployed recursively from `home-manager/pi-box-templates/`; `pi-box init` requires a template Dockerfile and falls back to the generic manifest when a template has no `pi-box.toml`. The shared base provides Node 24. The published `@sysid/mmdlint` package requires Node 20 or newer and validates Mermaid blocks without a browser.

## Goals / Non-Goals

**Goals:**

- Provide `mmdlint` only in the `knowledge-assistant` project image.
- Keep the template on the existing shared base and generic grant defaults.
- Make the npm package version explicit so the direct dependency does not float on rebuild.

**Non-Goals:**

- Add mmdlint to every pi-box sandbox or change the shared base image.
- Add project-specific host mounts, environment variables, or privileged mode.
- Modify or scaffold the external knowledge-assistant workspace as part of this repository change.

## Decisions

- Add `home-manager/pi-box-templates/knowledge-assistant/Dockerfile.pi`, based on `pi-sandbox`, and install `@sysid/mmdlint@0.1.1` globally. The package supports Node 20+, so it is compatible with the base's Node 24. Pinning the package is preferable to `latest`, which could change independently of this configuration.
- Do not add a `pi-box.toml`. The existing init flow copies the generic manifest when a template omits one, so the new template needs no separate grants configuration.
- Rely on the existing recursive Home Manager deployment. Update the template catalog in `AGENTS.md` and add the requirement delta described in the spec; no wrapper or module changes are needed.
- Verify using a disposable scaffolded project: build the template image and run `mmdlint` against Markdown containing valid and invalid Mermaid blocks. Do not run repository sync scripts or modify linked repositories.

## Risks / Trade-offs

- [The npm package or registry may be unavailable during an image build] → The failure is isolated to this template; other pi-box images remain usable. The pinned direct package version avoids silently switching to a new release.
- [The shared base Node version may change] → Recheck the package's Node engine requirement if the base runtime changes.
- [The generic manifest may be overridden by a project when scaffolded] → This is existing pi-box behavior; only the generated template defaults are in scope.

## Migration Plan

After applying Home Manager, `pi-box init knowledge-assistant` will be available. Use it in a new or disposable workspace, then launch pi-box to build and exercise the image. Existing scaffold files remain protected by the current init prompt/backup behavior. Rollback by removing the template and its catalog/spec entries; no existing project image or workspace data needs migration.
