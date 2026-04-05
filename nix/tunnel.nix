# Cloudflare Tunnel for proxying SSH through zero-trust
#
# Setup:
#   cloudflared tunnel login
#   cloudflared tunnel create salmon
#   cloudflared tunnel route dns salmon ssh.yourdomain.com
#   sudo cp ~/.cloudflared/*.json /etc/cloudflared/credentials.json
#   sudo cp ~/.cloudflared/cert.pem /etc/cloudflared/cert.pem
#   sudo chown -R root:root /etc/cloudflared
#   sudo nixos-rebuild switch --flake .#salmon

{
  ...
}:

{
  services.cloudflared = {
    enable = true;
    tunnels.salmon = {
      credentialsFile = "/etc/cloudflared/credentials.json";
      default = "http_status:404";
      ingress = {
        "<WISH-RIGHT-NOW>" = "ssh://localhost:22";
      };
    };
  };
}
