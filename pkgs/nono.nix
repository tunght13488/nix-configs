# nono: pin the upstream release binary.
#
# Consumers: overlays/default.nix (`modifications`), home-manager/pi-sandbox.nix.
#
# 26.05 pins nono 0.61.1, which predates the profile features pi-box relies on
# (custom credential routes with endpoint rules). Upstream releases a static
# musl binary, so this packages it directly instead of building the Rust crate.
# Bump `version` and the hash deliberately.
#
# Deliberately NOT wrapped with wrapProgram: pi-box execs this ELF through a
# symlink named `pi` so herdr's foreground-process detection recognizes the
# pane (a wrapProgram shell wrapper would present as `.nono-wrapped` instead).
# The runtime helpers nono shells out to (socat, bubblewrap) are therefore put
# on pi-box's PATH by home-manager/pi-sandbox.nix.
#
# shortcut: bpftrace (eBPF monitoring, present in the nixpkgs package) is not
# included - it drags in LLVM and monitoring degrades gracefully without it.
# Add it if audit telemetry ever needs kernel-level event capture.
{ lib
, stdenvNoCC
, fetchurl
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "nono";
  version = "0.82.0";

  src = fetchurl {
    url = "https://github.com/nolabs-ai/nono/releases/download/v${finalAttrs.version}/nono-v${finalAttrs.version}-x86_64-unknown-linux-musl.tar.gz";
    hash = "sha256-LYE4TZAlx/+cnim49eg9OcxnObo3uooMUP5QzupGU94=";
  };

  # The archive is a single flat file, so stdenv's source-root auto-detection
  # would reject it.
  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 nono "$out/bin/nono"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Secure, kernel-enforced sandbox for AI agents (pinned upstream release)";
    homepage = "https://nono.sh";
    license = licenses.asl20;
    mainProgram = "nono";
    platforms = [ "x86_64-linux" ];
  };
})
