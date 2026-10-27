# Tasks

## 1. Template files

- [x] 1.1 Create `home-manager/pi-box-templates/default/Dockerfile.pi` and `pi-box.toml` with today's generic content, and verify by diffing against the `DOCKERFILE_TEMPLATE` / `MANIFEST_TEMPLATE` heredocs still in `pi-box.sh` (content must match before task 2.3 removes them)
- [x] 1.2 Create `home-manager/pi-box-templates/php83/` (sury PHP 8.3: composer, bcmath, cli, curl, dom, gd, mbstring, mysql, soap, xml, zip; manifest with `DB_HOST = "host.docker.internal"`) and verify with a scratch build: `docker build -t pi-tpl-php83 .` from a temp dir containing the template as `Dockerfile.pi`, then `docker run --rm pi-tpl-php83 php -m` shows gd, pcntl, posix, pdo_mysql
- [x] 1.3 Create `home-manager/pi-box-templates/php82/` (same extension list on sury 8.2, same manifest) and verify the same way with `php -r 'echo PHP_VERSION'` printing 8.2.x and gd loaded
- [x] 1.4 Create `home-manager/pi-box-templates/java8/` (Temurin 8 JDK from Adoptium apt, Maven 3.6.3 tarball at `/opt` with `mvn` symlinked, `JAVA_HOME` set, manifest with `volumes = ["pi-m2-example:/root/.m2"]`) and verify `docker run --rm pi-tpl-java8 mvn -version` reports 3.6.3 on Java 1.8
- [x] 1.5 Create `home-manager/pi-box-templates/node22/` (Node 22.23.4 tarball over `/usr/local`, yarn classic via npm) and verify `node --version` is 22.x, `yarn --version` is 1.22.x, and `pi --version` still runs on the image

## 2. init rework in pi-box.sh

- [x] 2.1 Replace `cmd_init` with template resolution (no name -> `default`; validate directory under `$SANDBOX_DIR/templates/`; unknown name dies with the list), `--list`, and copying `Dockerfile.pi` plus the template's `pi-box.toml` when present (else `default`'s), and verify in a scratch dir: `pi-box init --list` prints the five names and `pi-box init php83` produces files matching the template
- [x] 2.2 Add overwrite handling to `cmd_init`: one timestamp per run (`date +%Y%m%d-%H%M%S`), batch prompt on a tty, `cp -a` backup to `<file>.<stamp>.bak` before writing, `-f/--force` skipping the prompt (still backing up), non-tty leaving files alone, and verify in a scratch dir that answering yes backs up both files with one shared timestamp, answering no (or piping from `/dev/null`) leaves them untouched, and `--force` overwrites without a prompt
- [x] 2.3 Remove the `DOCKERFILE_TEMPLATE` and `MANIFEST_TEMPLATE` heredocs from `pi-box.sh` and the now-unneeded `excludeShellChecks` entry in `home-manager/pi-sandbox.nix`, and verify `make home-build` passes shellcheck
- [x] 2.4 Update `usage()` to document `init [--force] [template]` and `--list`, and verify `pi-box help` renders the new text

## 3. Manifest volumes grant

- [x] 3.1 Add a `VOLUME` record to `parse_manifest` (`(.volumes[]? | "VOLUME\t" + tostring)`) and a pass-through loop in `cmd_run` (`args+=(--volume "$item")`), document the key in `templates/default/pi-box.toml`, and verify by running a sandbox whose manifest declares a named volume: files written to the volume path in one run are present in the next run
- [x] 3.2 Update the gh/ports/mounts/env comment block in `templates/default/pi-box.toml` to explain `volumes` (named Docker volumes, per-project names, prune note) and verify the manifest still parses with `yq -p toml`

## 4. Deployment and docs

- [x] 4.1 Add `home.file` entries in `home-manager/pi-sandbox.nix` deploying `pi-box-templates/**` to `.pi/sandbox/templates/`, run `nixpkgs-fmt` on the edited nix files, and verify `make home-build` succeeds; after the user runs `make home`, confirm the five template directories exist under `~/.pi/sandbox/templates/`
- [x] 4.2 Update the pi-box section of `AGENTS.md` (template list with per-template intent, init flags, backup naming and shared timestamp, `volumes` grant with the Maven example) and verify the documented commands match the implemented behavior

## 5. Integration verification

- [x] 5.1 Scaffold a scratch worktree with `pi-box init java8`, run `pi-box -p "mvn -version"` from it, and verify the Maven cache volume persists across a second run (second run reports cached artifacts instead of re-downloading)
- [x] 5.2 In `fc-es-starter-pack/oms_backend_alpha` (after the user scaffolds it), run a single Maven test through the sandbox to verify Temurin 8 works on bookworm and the Fluent maven repo is reachable from the sandbox, using the reference-jar fallback from that project's AGENTS.md only if reachability fails
- [x] 5.3 Run `openspec validate add-pi-box-templates` and fix any validation errors or strict warnings in the change artifacts
