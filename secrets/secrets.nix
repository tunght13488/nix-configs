let
  # User SSH keys — add any key that should be able to decrypt secrets
  ssh_agenix = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBiiNxhT4cABu/y3Pm/yx5g6oWDb1BKJ2IxXOhm3DIuU";

  allKeys = [
    ssh_agenix
  ];
in
{
  "ngrok-authtoken.age".publicKeys = allKeys;
}
