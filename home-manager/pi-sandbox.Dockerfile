# syntax=docker/dockerfile:1.7
# Base image for pi-box sandboxes.
#
# Deployed to ~/.pi/sandbox/Dockerfile by home-manager/pi-sandbox.nix and built
# on demand by the `pi-box` wrapper (tag: pi-sandbox). Per-project images are
# `FROM pi-sandbox`, so every layer here is shared across all projects.
#
# Layer order is stable-first, volatile-last: the Pi install is the final layer,
# so bumping PI_VERSION never invalidates the apt tooling layers below it.
ARG BASE_IMAGE=node:24-slim
FROM ${BASE_IMAGE}

# --- stable layers: OS tooling ---------------------------------------------
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      fd-find \
      gh \
      git \
      jq \
      less \
      python3 \
      ripgrep \
      unzip \
      vim-tiny \
      xz-utils \
    && rm -rf /var/lib/apt/lists/* \
    # Debian installs the binary as `fdfind`; pi probes for `fd` or `fdfind`,
    # this symlink is for humans at the shell.
    && ln -sf "$(command -v fdfind)" /usr/local/bin/fd

# --- stable layer: container-safe git overrides ----------------------------
# pi-box mounts the host's ~/.config/git read-only at /root/.config/git. Git
# reads this file (~/.gitconfig) after the XDG global config, so single-valued
# settings here win, and an empty credential.helper resets the accumulator -
# which drops the host's /nix/store credential-helper path (absent in here).
#
# The url.*.insteadOf entry lets GitHub SCP-style SSH remotes (`git@github.com:`)
# resolve over HTTPS, where the gh credential helper above can authenticate them.
# No SSH agent is ever mounted, so without this every SSH-form remote would fail.
# The rewrite is transport-level only: each checkout keeps its configured origin.
RUN cat > /root/.gitconfig <<'GITCONFIG'
[credential]
	helper =
[credential "https://github.com"]
	helper = ""
	helper = /usr/bin/gh auth git-credential
[credential "https://gist.github.com"]
	helper = ""
	helper = /usr/bin/gh auth git-credential
[url "https://github.com/"]
	insteadOf = git@github.com:
[core]
	editor = vi
	askpass =
[diff]
	tool =
[merge]
	tool =
[difftool]
	prompt = false
[mergetool]
	prompt = false
GITCONFIG

# --- volatile layer: Pi itself ---------------------------------------------
# Pinned by the wrapper's --build-arg so the image tracks the host Pi version.
ARG PI_VERSION=latest
RUN npm install -g --ignore-scripts "@earendil-works/pi-coding-agent@${PI_VERSION}" \
    && npm cache clean --force

WORKDIR /workspace
CMD ["pi"]
