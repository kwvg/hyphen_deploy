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
  ingress = lib.mapAttrs' (_: svc: lib.nameValuePair svc.hostname svc.target) cfg.tunnels.services;
  anyEnabled = ingress != { };
in
{
  services.cloudflared = lib.mkIf anyEnabled {
    enable = true;
    tunnels.${config.networking.hostName} = {
      credentialsFile = "/etc/cloudflared/credentials.json";
      default = "http_status:404";
      inherit ingress;
    };
  };
}
