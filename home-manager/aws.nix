{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  programs.awscli.enable = true;
  programs.awscli.settings = {
    "profile sl-dev" = {
      sso_start_url = "https://secretlab.awsapps.com/start#";
      sso_region = "ap-southeast-1";
      sso_registration_scopes = "sso:account:access";
      sso_account_id = "484750731673";
      sso_role_name = "SeniorBackendDeveloper";
      region = "ap-southeast-1";
      output = "json";
    };
  };
  home.packages = [ pkgs.ssm-session-manager-plugin ];
}
