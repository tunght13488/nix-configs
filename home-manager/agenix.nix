# agenix secret management — identity paths and secret declarations
{ config, lib, pkgs, ... }:
{
  age.identityPaths = [
    "/home/tung/.ssh/ssh_agenix"
  ];

  age.secrets.ngrok-authtoken.file = ../secrets/ngrok-authtoken.age;
  age.secrets.github-token.file = ../secrets/github-token.age;

  # Write ~/.config/nix/nix.conf with the GitHub access token at activation time.
  # nix.settings is intentionally not used: it would create a read-only store symlink
  # at the same path, conflicting with this runtime write.
  home.activation.nixGithubAccessToken = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
    $DRY_RUN_CMD ${pkgs.systemd}/bin/systemctl --user start agenix.service

    $DRY_RUN_CMD install -d -m 700 "${config.xdg.configHome}/nix"
    $DRY_RUN_CMD install -m 600 /dev/null "${config.xdg.configHome}/nix/nix.conf"
    {
      printf 'access-tokens = github.com='
      cat "${config.age.secrets.github-token.path}"
    } > "${config.xdg.configHome}/nix/nix.conf"
  '';
}
