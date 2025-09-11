{ ... }:
{
  # You do not need to change these by hand. install-nixos.sh will edit these later
  my.gcpProjectId = "dev-vm-provisioning";
  my.hostname = "coral";
  my.user.name = "norman";
  my.user.sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL1lqGCwLgpCJ3ge0pVGTj+8k4x7e/6+MT23XrRc9SQd norman_mbp_m1_pro";

  system.stateVersion = "24.11"; # Don't change this after initial installation

  my.enableInteractiveCli = true;
  my.enableFullNeovim = true;
}
