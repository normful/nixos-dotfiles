# Custom package: cowsay pinned to v3.8.4
#
# Uses overrideAttrs to replace the source of nixpkgs' cowsay with a
# specific GitHub tag. This demonstrates how to pin a package to a
# specific revision while inheriting all other build logic (phases,
# dependencies, install steps) from nixpkgs.
#
# Alternatives to this approach:
# - fetchurl on the release tarball (if GitHub sources are unreliable)
# - overrideAttrs with a vendorSha256 override to update Go/Rust deps
#
# This is a standalone package (called via callPackage), not an overlay.
# It's used in the system config as: callPackage ../../packages/cowsay { }
{
  cowsay,
  fetchFromGitHub,
}:

cowsay.overrideAttrs (old: {
  name = "cowsay-3.8.4-pinned";
  src = fetchFromGitHub {
    owner = "cowsay-org";
    repo = "cowsay";
    rev = "v3.8.4";
    sha256 = "sha256-m3Rndw0rnTBLhs15KqokzIOWuYl6aoPqEu2MHWpXRCs=";
  };
})
