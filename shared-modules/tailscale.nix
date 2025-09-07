{
  config,
  lib,
  pkgs-stable,
  ...
}:
{
  environment.systemPackages = with pkgs-stable; [
    tailscale
    jq
  ];

  sops.secrets = {
    tailscaleAuthKey = { };
  };

  services.tailscale = {
    enable = true;
    interfaceName = "tailscale0";
    openFirewall = true;
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  systemd.services.tailscale-autoconnect = {
    description = "Automatic connection to Tailscale tailnet";
    after = [
      "network-pre.target"
      "tailscale.service"
    ];
    wants = [
      "network-pre.target"
      "tailscale.service"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    path = with pkgs-stable; [
      tailscale
      jq
    ];
    script = ''
      sleep 2

      status="$(tailscale status -json | jq -r .BackendState)"
      if [ $status = "Running" ]; then
        echo "Tailscale already running"
        exit 0
      fi

      echo "Running tailscale up"
      tailscale up \
        --auth-key "file:${config.sops.secrets.tailscaleAuthKey.path}" \
        --ssh \
        --reset \
        --advertise-exit-node
    '';
  };
}
