# Host configuration

{
  machine = {
    hostname = "keplar";
    username = "mantle";
    hostId = "<I-COULD-REALLY-USE-A-WISH-RIGHT-NOW>";
    healthcheckUUID = "ebd0a0a2-a7e0-baad-f00d-68b6b72699c8";
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
    tunnels = {
      ssh = {
        enabled = true;
        hostname = "<WISH-RIGHT-NOW>";
      };
      services = {
        portainer = {
          hostname = "<AIRPLANES-IN-THE-NIGHT-SKY>";
          target = "http://localhost:9000";
        };
      };
    };
    wireguard = {
      enabled = true;
      address = "10.100.0.2/24";
      peers = [
        {
          publicKey = "<SALMON_PUBKEY>";
          endpoint = "<SALMON_PUBLIC_IP>:51820";
          allowedIPs = [ "10.100.0.1/32" ];
        }
      ];
    };
  };
}
