## Context

`home-manager/herdr.nix` generates `~/.config/herdr/config.toml` from a Nix attrset via `pkgs.formats.toml` and places it with `xdg.configFile`. This creates a symlink to the Nix store, where files are read-only. To iterate on herdr settings, the user must edit `herdr.nix`, run `home-manager switch`, then restart or reload herdr — a slow cycle for exploration.

The codebase already uses `home.activation` for cases where Nix-managed symlinks are inappropriate: `agenix.nix` writes `nix.conf` at activation time instead of using `nix.settings`, and `home-manager/php.nix` adjusts directory permissions post-activation.

## Goals / Non-Goals

**Goals:**
- Config file at `~/.config/herdr/config.toml` is a writable real file, not a symlink
- Nix attrset in `herdr.nix` remains the single source of truth for the baseline
- Subsequent `home-manager switch` runs do not overwrite user edits
- Simple: no helper scripts, diff tools, or multi-file configs

**Non-Goals:**
- Auto-syncing the live config back to the Nix attrset
- Diff helpers or reset automation (`make herdr-*`)
- Multi-file config merging (herdr doesn't support it anyway)
- A reusable pattern for other modules (out of scope for this change)

## Decisions

### Use `home.activation` copy-once instead of `xdg.configFile` symlink

**Rationale:** `xdg.configFile` with `source` always creates a symlink to the store. `home.activation` gives full control: copy the generated file on first run, then leave it alone.

**Alternatives considered:**

| Approach | Verdict |
|---|---|
| `mkOutOfStoreSymlink` to repo file | Two sources of truth (attrset + TOML file), they diverge |
| Conditional `text` vs `source` with env var | `text` overwrites on every switch, losing user edits |
| Shell wrapper / merge tool | Unnecessary complexity for a single config file |
| Manual `cp` + `rm` by user | No automation, easy to forget |

### Guard: only copy if file is missing or still a symlink

```
if [ ! -f "$target" ] || [ -L "$target" ]; then
  cp ${herdrConfigToml} "$target"
fi
```

- `! -f`: file doesn't exist → fresh install, copy baseline
- `-L`: file is a symlink → legacy state from prior `xdg.configFile`, copy over it to replace with real file
- Otherwise: real file exists → user is iterating, leave it alone

### Activation ordering: after `writeBoundary`

Following the existing `php.nix` pattern (`lib.hm.dag.entryAfter [ "writeBoundary" ]`) ensures `~/.config/herdr/` exists before the copy.

### Reset mechanism: manual, documented in comment

```
# Reset baseline:
#   cp ~/.config/herdr/config.toml ~/.config/herdr/config.toml.bak
#   rm ~/.config/herdr/config.toml
#   home-manager switch
```

No automation. Two commands, hard to do accidentally.

## Risks / Trade-offs

- **Config drift**: The Nix attrset and the live file will diverge during iteration. This is expected and intentional. The user reconciles manually when satisfied with changes.
- **Silent baseline updates**: If the user changes the Nix attrset and runs `home-manager switch`, the live file is NOT updated (it's a real file, guard skips it). The user must `rm` + switch to pick up the new baseline. This is the core trade-off of "copy-once."
- **Accidental reset**: `rm` without `cp` backup loses user edits. Mitigated by the module comment documenting the backup step.
