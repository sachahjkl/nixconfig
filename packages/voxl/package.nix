# voxl, browser remote desktop for an X11 display (github:tembo/voxl), built
# with the project's own derivation at a pinned main-branch commit.
{pkgs}: let
  src = pkgs.fetchFromGitHub {
    owner = "tembo";
    repo = "voxl";
    # The main branch after 0.3.4: HTTPS (--tls), which a browser needs
    # for WebCodecs anywhere but localhost, is in no release yet.
    rev = "2ea4f8f0e491d570e38abad49b813550f1570385";
    hash = "sha256-iB/prNxKj6jwozgC/+08qHQbhpeDeH5dQGymbX+pcKo=";
  };
  # Upstream still references the deprecated pkgs.xorg.* aliases removed in 26.05.
  xorgCompat = {
    inherit (pkgs) libxcb;
    xorgserver = pkgs.xorg-server;
  };
in {
  # The derivation type-checks the web client with tsc before the build; the
  # project pins TypeScript 5.8 and nixpkgs' newer one rejects a lib type
  # (ArrayBufferLike). The bundle is esbuild's (build.rs), which does not
  # depend on that check.
  voxl = (pkgs.callPackage "${src}/default.nix" {xorg = xorgCompat;}).overrideAttrs {preBuild = "";};
  # Xvfb with the project's patch for smooth scrolling (its README).
  xvfb = pkgs.callPackage "${src}/xvfb.nix" {xorg = xorgCompat;};
}
