# agenix secret management — identity paths and secret declarations
{ ... }:
{
  age.identityPaths = [
    "/home/tung/.ssh/ssh_agenix"
  ];

  age.secrets.ngrok-authtoken.file = ../secrets/ngrok-authtoken.age;
}
