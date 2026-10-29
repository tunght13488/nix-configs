# nixos/agenix.nix — system-level agenix secrets
#
# Home Manager already runs agenix for user secrets (home-manager/agenix.nix).
# Services need their secrets during boot, before any user session exists, so
# the NixOS module is imported too. Both use the same identity key and the same
# `secrets/` directory.
{ ... }:
{
  age.identityPaths = [
    "/home/tung/.ssh/ssh_agenix"
  ];

  # Environment file for the LiteLLM service (LITELLM_MASTER_KEY,
  # LITELLM_SALT_KEY). Read by systemd as root via EnvironmentFile=, so the
  # service's DynamicUser never needs to open it.
  #
  # Decrypt from the `secrets/` directory (the agenix CLI reads ./secrets.nix
  # from the working directory and keys rules by the given path), with the file
  # immediately after the flag (`-d -i KEY FILE` is parsed as file "-i"):
  #   cd secrets && agenix -d litellm-env.age -i ~/.ssh/ssh_agenix
  # Never with sudo: the identity key belongs to the user.
  age.secrets.litellm-env = {
    file = ../secrets/litellm-env.age;
    owner = "root";
    group = "root";
    mode = "0400";
  };
}
