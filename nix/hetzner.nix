# Host-specific configuration

{
  lib,
  ...
}:

{
  # Intel platform
  boot.kernelModules = [ "kvm-intel" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Host identity
  networking.hostName = "salmon";

  # ZFS requires unique hostId, generate randomly
  networking.hostId = "<I-COULD-REALLY-USE-A-WISH-RIGHT-NOW>";

  # Static networking via systemd-networkd
  networking.useNetworkd = true;
  networking.useDHCP = false;

  # Use rescue OS to get NIC name and get IP config from console
  systemd.network.enable = true;
  systemd.network.networks."30-wan" = {
    matchConfig.Name = "<WISH-RIGHT-NOW>";
    networkConfig.DHCP = "no";
    address = [
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

  # Using non-Hetzner nameservers
  networking.nameservers = [
    "1.1.1.1"
    "8.8.8.8"
  ];

  # Hetzner blocks UDP 53 without a firewall carve-out
  environment.etc."resolv.conf".text = lib.mkForce ''
    nameserver 1.1.1.1
    nameserver 8.8.8.8
    options use-vc
  '';
}
