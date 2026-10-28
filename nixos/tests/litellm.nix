# nixos/tests/litellm.nix — database-backed LiteLLM integration test
#
# Exercises the parts that only appear when LiteLLM really talks to PostgreSQL:
# Prisma schema bootstrap, the generated Python client, model persistence across
# restarts, and failing closed when the database is unreachable.
#
# This is NOT wired into `nix flake check` because a NixOS VM test needs
# hardware virtualisation (/dev/kvm), which plain build hosts may lack. Run it
# explicitly:
#
#   nix build --no-link --impure --expr '
#     let
#       f = builtins.getFlake "path:/home/tung/code/nix-configs/nix_main";
#     in
#     (f.inputs.nixpkgs.legacyPackages.x86_64-linux.testers.nixosTest
#       (import /home/tung/code/nix-configs/nix_main/nixos/tests/litellm.nix {
#         inherit f;
#       }))'
{ f }:

let
  system = "x86_64-linux";

  overlays = [
    f.overlays.additions
    f.overlays.modifications
    f.overlays.unstable-packages
    f.overlays.phps
    f.overlays.mysql80-packages
  ];
in
{
  name = "litellm-db";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [
        (f + "/nixos/postgres.nix")
        (f + "/nixos/litellm.nix")
      ];

      nixpkgs.overlays = overlays;

      # The real deployment takes these from agenix; the test only needs the
      # two keys to exist.
      services.litellm.environmentFile = pkgs.writeText "litellm-test-env" ''
        LITELLM_MASTER_KEY=sk-test-master
        LITELLM_SALT_KEY=sk-test-salt
      '';

      # Nothing in this test reaches a real provider.
      networking.firewall.enable = false;

      # LiteLLM peaks around 700MB, and the test also has to cope with being
      # emulated (no KVM available on some builders).
      virtualisation.memorySize = 2048;
    };

  testScript = ''
    import json

    machine.start()
    machine.wait_for_unit("postgresql.service")

    # Schema bootstrap (prisma db push) plus the generated Python client both
    # have to work for the unit to come up.
    machine.wait_for_unit("litellm.service", timeout=1800)
    machine.wait_until_succeeds("curl -fsS http://127.0.0.1:4001/health/liveliness", timeout=1800)

    with subtest("Prisma schema was applied"):
        machine.succeed(
            "sudo -u postgres psql -d litellm -c '\\dt' | grep -q LiteLLM_ProxyModelTable"
        )

    with subtest("a model added through the API is stored in PostgreSQL"):
        machine.succeed(
            """curl -fsS -X POST http://127.0.0.1:4001/model/new \
                 -H 'Authorization: Bearer sk-test-master' \
                 -H 'Content-Type: application/json' \
                 -d '{"model_name":"vm-test-model","litellm_params":{"model":"openai/gpt-4o-mini","api_key":"sk-dummy"}}'"""
        )
        machine.succeed(
            """sudo -u postgres psql -d litellm -tAc \
                 'select "model_name" from "LiteLLM_ProxyModelTable"' | grep -q vm-test-model"""
        )

    with subtest("the model survives a service restart"):
        machine.systemctl("restart litellm.service")
        machine.wait_for_unit("litellm.service", timeout=1800)
        machine.wait_until_succeeds("curl -fsS http://127.0.0.1:4001/health/liveliness", timeout=1800)
        info = machine.succeed(
            "curl -fsS http://127.0.0.1:4001/model/info -H 'Authorization: Bearer sk-test-master'"
        )
        assert "vm-test-model" in json.loads(info)["data"][0]["model_name"]

    with subtest("LiteLLM does not run without its database"):
        # `requires = [ postgresql.service ]` plus the enforced schema check mean
        # LiteLLM stops rather than serving a half-working Admin UI.
        machine.systemctl("stop postgresql.service")
        machine.wait_until_fails("systemctl is-active --quiet litellm.service", timeout=120)
  '';
}
