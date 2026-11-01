{
  builders-use-substitutes = true;
  # 256 MiB. The default of 1 MiB causes "download buffer is full" warnings.
  download-buffer-size = 268435456;
  extra-experimental-features = [
    "flakes"
    "nix-command"
  ];
  extra-substituters = [
    "https://cache.homelab.sacha.house"
    "https://hyprland.cachix.org"
    "https://cache.numtide.com"
    "https://nix-community.cachix.org"
    "https://sachahjkl.cachix.org"
    "https://install.determinate.systems"
  ];
  extra-trusted-public-keys = [
    "homelab-cache-1:ZaUHSv8slKsAKc9kd0AGI8p1HUjUumfho7ShgUVlnUg="
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    "sachahjkl.cachix.org-1:cepX7PCUV88hCchnh9prZM5V72wRkCf6oSJL6JfgWs0="
  ];
  flake-registry = "";
  http-connections = 50;
  show-trace = true;
  trusted-users = [
    "root"
    "@wheel"
  ];
  use-xdg-base-directories = true;
  warn-dirty = false;
}
