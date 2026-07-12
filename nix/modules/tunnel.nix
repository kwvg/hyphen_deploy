# Cloudflare Tunnel for proxying services
#
# Setup:
#   cloudflared tunnel login
#   cloudflared tunnel create hostname
#   cloudflared tunnel route dns hostname ssh.yourdomain.com
#   sudo cp ~/.cloudflared/*.json /etc/cloudflared/credentials.json
#   sudo cp ~/.cloudflared/cert.pem /etc/cloudflared/cert.pem
#   sudo chown -R root:root /etc/cloudflared
#   sudo nixos-rebuild switch --flake .#hostname

{ config, lib, ... }:

let
  cfg = config.machine;
  sshCfg = cfg.tunnels.ssh;
  serviceIngress = lib.mapAttrs' (
    _: svc: lib.nameValuePair svc.hostname {
      service = svc.target;
      originRequest.originServerName = svc.hostname;
    }
  ) cfg.tunnels.services;
  sshIngress = lib.optionalAttrs sshCfg.enabled { ${sshCfg.hostname} = "tcp://localhost:22"; };
  ingress = serviceIngress // sshIngress;
  anyEnabled = sshCfg.enabled || cfg.tunnels.services != { };
in
{
  assertions = [
    {
      assertion = !sshCfg.enabled || sshCfg.hostname != "";
      message = "machine.tunnels.ssh.hostname must be set when SSH tunnel is enabled";
    }
    {
      assertion =
        builtins.length (builtins.attrNames (builtins.intersectAttrs sshIngress serviceIngress)) == 0;
      message = "machine.tunnels.ssh.hostname must not collide with any service tunnel hostname";
    }
  ];

  # Bootstrap SSH: listen on all interfaces, open port 22 in firewall
  # Tunneled  SSH: bind to loopback only, accessed via Cloudflare tunnel
  services.openssh.listenAddresses = lib.mkIf sshCfg.enabled [
    {
      addr = "127.0.0.1";
      port = 22;
    }
    {
      addr = "::1";
      port = 22;
    }
  ];

  networking.firewall.allowedTCPPorts = lib.mkIf (!sshCfg.enabled) [ 22 ];

  services.cloudflared = lib.mkIf anyEnabled {
    enable = true;
    tunnels.${config.networking.hostName} = {
      credentialsFile = "/etc/cloudflared/credentials.json";
      default = "http_status:404";
      inherit ingress;
    };
  };
}
