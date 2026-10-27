# Tasks

## 1. Shared base image and documentation

- [x] 1.1 Add the distro's `python3` package to the stable apt install layer in `home-manager/pi-sandbox.Dockerfile`; build the base image and verify `docker run --rm pi-sandbox python3 --version` succeeds and reports Python 3.
- [x] 1.2 Update the common-base toolchain inventory in `AGENTS.md` and the comments in all five shipped template Dockerfiles (`default`, `php82`, `php83`, `java8`, `node22`) to include Python 3; verify the listings with `rg -n 'python3' AGENTS.md home-manager/pi-box-templates/*/Dockerfile.pi` and run `git diff --check`.

## 2. Derived image verification

- [x] 2.1 Build a representative derived image using `home-manager/pi-box-templates/default/Dockerfile.pi` and verify `docker run --rm pi-box-python-check python3 --version` succeeds and reports Python 3 without project-specific Python installation.
