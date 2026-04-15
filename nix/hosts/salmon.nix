# Host configuration
#
# - Remember to change your SSH key
# - The version of Rust deployed is NOT pinned, `rustup` will let you select your toolchain

{
  machine = {
    hostname = "salmon";
    username = "smolt";
    hostId = "<I-COULD-REALLY-USE-A-WISH-RIGHT-NOW>";
    healthcheckUUID = "ebd0a0a2-a7e0-baad-f00d-68b6b72699c7";
    nicName = "<WISH-RIGHT-NOW>";
    sshAuthorizedKeys = [
      "<CAN-WE-PRETEND-THAT-AIRPLANES-IN-THE-NIGHT-SKY-ARE-LIKE-SHOOTING-STARS>"
    ];
    addresses = [
      "<WISH-RIGHT-NOW>"
      "<CAN-WE-PRETEND-THAT-AIRPLANES-IN-THE-NIGHT-SKY-ARE-LIKE-SHOOTING-STARS>"
    ];
    routes = [
      {
        Gateway = "<I-COULD-REALLY-USE-A-WISH-RIGHT-NOW>";
        GatewayOnLink = true;
      }
      { Gateway = "<WISH-RIGHT-NOW>"; }
    ];
  };

  # SSH bound to localhost, accessed via Cloudflare tunnel
  services.openssh.listenAddresses = [
    {
      addr = "127.0.0.1";
      port = 22;
    }
    {
      addr = "::1";
      port = 22;
    }
  ];

  # Cloudflare Tunnel for proxying services
  #
  # Setup:
  #   cloudflared tunnel login
  #   cloudflared tunnel create salmon
  #   cloudflared tunnel route dns salmon ssh.yourdomain.com
  #   sudo cp ~/.cloudflared/*.json /etc/cloudflared/credentials.json
  #   sudo cp ~/.cloudflared/cert.pem /etc/cloudflared/cert.pem
  #   sudo chown -R root:root /etc/cloudflared
  #   sudo nixos-rebuild switch --flake .#salmon
  #
  services.cloudflared = {
    enable = true;
    tunnels.salmon = {
      credentialsFile = "/etc/cloudflared/credentials.json";
      default = "http_status:404";
      ingress = {
        "<WISH-RIGHT-NOW>" = "tcp://localhost:22";
        "<AIRPLANES-IN-THE-NIGHT-SKY>" = "http://localhost:9000";
      };
    };
  };
}
