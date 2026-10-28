# Tasks

## 1. PostgreSQL and secret foundation

- [x] 1.1 Add and import a PostgreSQL module with a dedicated LiteLLM database and least-privilege role, loopback-only listening, and loopback-only trust authentication; verify the evaluated PostgreSQL configuration contains no non-loopback trust rule or listener.
- [x] 1.2 Wire the NixOS agenix module to the existing identity key and add an encrypted LiteLLM environment secret containing generated `LITELLM_MASTER_KEY` and stable `LITELLM_SALT_KEY` values; verify it decrypts at system activation and secret values do not appear in generated Nix configuration or the store.

## 2. Native LiteLLM service and database bootstrap

- [x] 2.1 Add and import a LiteLLM module using the packaged NixOS service on `127.0.0.1:4001`, a password-free loopback PostgreSQL URL, the agenix environment file, and `general_settings.store_model_in_db = true` with no static models; verify the evaluated service settings and config contain these values without plaintext secrets.
- [x] 2.2 Add a Nix-built, version-matched Prisma CLI/engine cache and Node runtime to the service, set the cache environment, require PostgreSQL before LiteLLM, and enable migration-failure enforcement; verify the cache builds and Prisma runs from it without a first-start network download.
- [x] 2.3 Add a focused NixOS VM integration test with a clean PostgreSQL database; verify LiteLLM initializes its schema, serves its health endpoint, persists a database-backed model across service restart, and fails startup when schema initialization is forced to fail.

## 3. HTTPS reverse proxy and streaming

- [x] 3.1 Update the existing LiteLLM vhost to retain forwarded headers and upstream while disabling response buffering and setting suitable long-lived request timeouts; verify the generated nginx configuration passes `nginx -t` and contains the streaming directives.

## 4. Full configuration and host verification

- [x] 4.1 Format and build the complete NixOS configuration with `make format` and `make os-build`; verify all new Nix files are included in the flake evaluation.
- [ ] 4.2 After operator activation, verify the Admin UI and API through `https://litellm.vm.local`, confirm ports 4001 and 5432 are not externally exposed, add a model through the UI, and confirm it persists after restart and supports a streamed request.
