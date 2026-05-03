let
  sacha = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJMYomE72hDxOemhx4f8EfHw1vDwAFAbE405j8IOL7d/ sacha";
in
{
  "sacha-gpg-private-keys.asc.age" = {
    publicKeys = [ sacha ];
    armor = true;
  };
}
