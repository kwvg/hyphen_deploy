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
    tunnels.services = {
      ssh = {
        hostname = "<WISH-RIGHT-NOW>";
        target = "tcp://localhost:22";
      };
      portainer = {
        hostname = "<AIRPLANES-IN-THE-NIGHT-SKY>";
        target = "http://localhost:9000";
      };
    };
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
}
