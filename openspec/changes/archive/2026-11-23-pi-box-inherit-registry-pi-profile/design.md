# Design

## Context

See `proposal.md` for motivation and `specs/pi-box-sandbox/spec.md` for the behavior contract. The Home Manager base profile currently extends `default`, adds the `developer` network profile and domain list, and grants only selected pi-box paths. The wrapper's generated launcher filters host `PATH` entries to Nix store paths. The installed `nolabs-ai/pi` profile instead allows outbound networking, grants `~/.pi` read-write and grants `~/.cache` read-write through `user_caches_linux`.

The GitHub token is currently stored at `~/.pi/sandbox/gh-token`, so it would be exposed by the upstream `~/.pi` grant. The OpenSpec command at `~/.npm-global/bin/openspec` is a symlink to `~/.npm-global/lib/node_modules/@fission-ai/openspec/bin/openspec.js`; the current pi-box policy denies that package and the launcher drops its bin directory.

## Goals / Non-Goals

**Goals:**

- Inherit the installed registry Pi profile in full, including its default-allow network policy, filesystem grants, and runtime groups.
- Keep the brokered GitHub token outside all sandbox grants and prevent launch with the old token path still present.
- Make the host OpenSpec CLI available by name with read-only package access.

**Non-Goals:**

- Reproduce or pin the registry profile locally, automatically install it, or remove any of its grants. The user selected the full upstream profile; its `~/.pi` and `~/.cache` read-write grants are intentional.
- Preserve the current default-deny egress behavior or restrict unauthenticated outbound traffic.
- Change the GitHub credential's endpoint list or its existing `/graphql` limitation.
- Change the `nix-configs` template; its existing OpenSpec requirement will be satisfied by the shared base profile.

## Decisions

1. **Extend `nolabs-ai/pi` rather than copy its policy.** Set the pi-box base profile's `extends` to the installed package name and leave upstream fields inherited. This keeps the registry profile as the source of truth. The package is already installed on this host; other hosts must install it with `nono pull nolabs-ai/pi` before running pi-box. Home Manager will not pull registry packages during activation.

2. **Remove pi-box's network filter.** Remove the local `network_profile = "developer"` and static `allow_domain` list rather than overriding the registry's `network.block: false`. Keep the per-run `pi-box-github` credential route and its `endpoint_rules`; those rules protect the real GitHub token when it is injected, but do not constrain direct, unauthenticated traffic. Preserve the existing `/graphql` rule and document its inability to distinguish query from mutation.

3. **Move the GitHub token to a sibling of Nono's profile directory.** Store it at `~/.config/nono/credentials/pi-box-gh-token` with owner-only permissions and do not grant that directory to the sandbox. The installed registry profile grants `~/.config/nono/profiles` and `profile-drafts`, but `nono why` confirms the new credentials path remains denied. Update the wrapper's `file://` route to this path. Before launching Nono, fail with a migration message if `~/.pi/sandbox/gh-token` still exists; do not copy, log, or read the token into Pi. A child `filesystem.deny` is not a substitute: inherited filesystem grants are additive and this Linux Landlock policy cannot carve a deny out of the broad `~/.pi` grant.

4. **Grant only the OpenSpec paths needed and explicitly extend the launcher PATH.** Add read access to `~/.npm-global/bin` and the OpenSpec package directory, not the whole npm global prefix. Extend the launcher's existing PATH filter to retain the exact `~/.npm-global/bin` entry in addition to Nix store paths. This makes `openspec` resolve by name while leaving unrelated host PATH entries filtered.

## Risks / Trade-offs

- **Broader host access** → Full inheritance grants `~/.pi`, `~/.cache`, Nono profile drafts, and upstream runtime-group paths to every pi-box project. This is intentional per the selected scope; the GitHub token must be moved before activation.
- **Unrestricted egress** → Pi and child tools can connect to arbitrary outbound destinations. Project profiles can opt back into blocking or filtering when a workload requires it.
- **GitHub credential scope** → Endpoint rules apply only to the brokered route, not general network access; the existing `POST /graphql` rule can carry mutations. Do not describe the overall GitHub API as read-only.
- **Registry package dependency** → A missing `nolabs-ai/pi` package prevents profile resolution. Keep installation as an explicit prerequisite rather than adding network-dependent Home Manager activation.
- **OpenSpec path drift** → The grant is tied to the current npm global prefix and package path. If OpenSpec moves, update the grant and launcher PATH together.

## Migration Plan

1. Confirm `nolabs-ai/pi` is installed (`nono pull nolabs-ai/pi` if missing).
2. Before applying the new Home Manager profile, move any existing token from `~/.pi/sandbox/gh-token` to `~/.config/nono/credentials/pi-box-gh-token`; create the credentials directory with mode `700` and set the file to mode `600`. The old path must be absent before the first sandbox run with the upstream profile.
3. Have a human apply Home Manager. The wrapper's legacy-path check must fail closed if step 2 was skipped.
4. Validate the deployed profile with `nono profile validate pi-box` and inspect its resolved inheritance. Verify that `nono why` allows reads of the OpenSpec package, denies writes to it, and denies reads of the new token path; verify `openspec --version` works inside pi-box and `pi.dev` is reachable.
5. Verify the brokered GitHub route still permits configured reads, rejects an unlisted destructive method before token injection, and records the denial. Treat the existing `/graphql` rule as the documented exception.

For rollback, restore the previous base-profile inheritance and network filter while keeping the token at the new host-side path and the wrapper pointed there. Do not move the token back under `~/.pi` until the upstream profile's broad `~/.pi` grant has been removed.
