{ ... }:
{
  # You do not need to change these by hand. install-nixos.sh will edit these later
  my.hostname = "beach";
  my.user.name = "norman";
  my.user.sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1lqGCwLgpCJ3ge0pVGTj+8k4x7e/6+MT23XrRc9SQd norman_mbp_m1_pro";
  my.gcpProjectId = "dev-vm-provisioning";

  nix.settings.download-buffer-size = 4294967296; # 4 GiB
  system.stateVersion = "24.11"; # Don't change this after initial installation
}
