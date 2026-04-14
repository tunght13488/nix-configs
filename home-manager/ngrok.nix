{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.ngrok;

  # Render a single endpoint attrset to YAML list item lines
  endpointToYaml =
    ep:
    lib.concatStringsSep "\n" (
      [
        "  - name: ${ep.name}"
        "    url: ${ep.url}"
        "    upstream:"
        "      url: ${ep.upstream.url}"
      ]
      ++ lib.optional (ep.upstream.protocol != null) "      protocol: ${ep.upstream.protocol}"
    );

  # Static config (no secrets) — goes into the Nix store and is symlinked.
  staticConfig =
    let
      endpointLines = lib.concatStringsSep "\n" (map endpointToYaml (lib.attrValues cfg.endpoints));
      hasEndpoints = cfg.endpoints != { };
    in
    pkgs.writeText "ngrok.yml" (
      ''
        version: "3"
      ''
      + lib.optionalString hasEndpoints ''
        endpoints:
        ${endpointLines}
      ''
    );

  # Path where the activation script writes the authtoken-only fragment.
  authtokenConfig = "${config.xdg.configHome}/ngrok/ngrok-authtoken.yml";
in
{
  options.programs.ngrok = {
    enable = lib.mkEnableOption "ngrok tunnel manager";

    package = lib.mkPackageOption pkgs "ngrok" { };

    authtokenFile = lib.mkOption {
      type = lib.types.str;
      description = ''
        Path to a file containing the ngrok authtoken (plain text, one line).
        Typically set to config.age.secrets.ngrok-authtoken.path.
      '';
      example = "/run/user/1000/agenix/ngrok-authtoken";
    };

    endpoints = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Endpoint label shown in the ngrok dashboard.";
            };

            url = lib.mkOption {
              type = lib.types.str;
              description = "Public ngrok URL for this endpoint.";
              example = "https://inherently-good-tarpon.ngrok-free.app";
            };

            upstream = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  url = lib.mkOption {
                    type = lib.types.str;
                    description = "Local upstream host:port or URL.";
                    example = "middleware.vm.local:443";
                  };
                  protocol = lib.mkOption {
                    type = lib.types.nullOr lib.types.str;
                    default = null;
                    description = "Upstream protocol override (e.g. \"http2\"). Omitted when null.";
                  };
                };
              };
              description = "Upstream connection settings.";
            };
          };
        }
      );
      default = { };
      description = "Named ngrok endpoint definitions.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Wrapper that always passes both config files so the authtoken fragment
    # is merged with the static endpoints config.
    home.packages = [
      (pkgs.writeShellScriptBin "ngrok" ''
        exec ${lib.getExe cfg.package} \
          --config ${lib.escapeShellArg authtokenConfig} \
          --config ${config.xdg.configHome}/ngrok/ngrok.yml \
          "$@"
      '')
    ];

    # Static part (version + endpoints) — symlinked by home-manager as usual.
    xdg.configFile."ngrok/ngrok.yml".source = staticConfig;

    # Authtoken fragment — written at activation time from the agenix secret.
    home.activation.ngrokAuthtokenConfig = lib.hm.dag.entryAfter [ "reloadSystemd" ] ''
      # Ensure agenix has decrypted secrets before we read the authtoken file.
      $DRY_RUN_CMD ${pkgs.systemd}/bin/systemctl --user start agenix.service

      $DRY_RUN_CMD install -d -m 700 "${config.xdg.configHome}/ngrok"
      $DRY_RUN_CMD install -m 600 /dev/null "${authtokenConfig}"
      {
        printf 'version: "3"\nagent:\n  authtoken: '
        cat "${cfg.authtokenFile}"
        printf '\n'
      } > "${authtokenConfig}"
    '';
  };
}
