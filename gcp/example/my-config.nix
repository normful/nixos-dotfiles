{ ... }:
{
  # You do not need to change these by hand. install-nixos.sh will edit these later
  my.hostname = "GCP_VM_HOSTNAME_PLACEHOLDER";
  my.user.name = "GCP_VM_USERNAME_PLACEHOLDER";
  my.user.sshPublicKey = "SSH_PUBLIC_KEY_PLACEHOLDER";
  my.gcpProjectId = "dev-vm-provisioning";

  nix.settings.download-buffer-size = 4294967296; # 4 GiB
  system.stateVersion = "24.11"; # Don't change this after initial installation
}
