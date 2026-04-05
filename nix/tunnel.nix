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
  # Bind SSH to localhost only, accessed via Cloudflare Tunnel
  services.openssh = {
    listenAddresses = [
      {
        addr = "127.0.0.1";
        port = 22;
      }
      {
        addr = "::1";
        port = 22;
      }
    ];
  };

  services.cloudflared = {
    enable = true;
    tunnels.salmon = {
      credentialsFile = "/etc/cloudflared/credentials.json";
      default = "http_status:404";
      # Remember to `cloudflared tunnel route dns salmon ssh.yourdomain.com` for every key here
      ingress = {
        "<WISH-RIGHT-NOW>" = "tcp://localhost:22";
        "<AIRPLANES-IN-THE-NIGHT-SKY>" = "http://localhost:9000";
      };
    };
  };
}
