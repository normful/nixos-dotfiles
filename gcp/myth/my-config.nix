{ ... }:
{
  # You do not need to change these by hand. install-nixos.sh will edit these later
  my.gcpProjectId = "GCP_PROJECT_ID_PLACEHOLDER";
  my.hostname = "GCP_VM_HOSTNAME_PLACEHOLDER";
  my.user.name = "GCP_VM_USERNAME_PLACEHOLDER";
  my.user.sshPublicKey = "SSH_PUBLIC_KEY_PLACEHOLDER";

  nix.settings.download-buffer-size = 4294967296; # 4 GiB
  system.stateVersion = "24.11"; # Don't change this after initial installation

  my.enableInteractiveCli = true;
  my.enableFullNeovim = true;
  my.enableDocker = true;
  my.enableLogTools = true;
  my.enableNetworkingTools = true;
  my.enableFileSyncTools = true;
  my.enableJujutsu = true;
  my.enableGitTools = true;
  my.enableMultiLangTools = true;
  my.enableConfigLangsTools = true;
  my.enableLangGo = true;
  my.enableLangRust = true;
  my.enableLangNix = true;
}
