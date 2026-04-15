# Host-specific network and identity configuration

{
  config,
  lib,
  ...
}:

let
  cfg = config.machine;
in
{
  # Intel platform
  boot.kernelModules = [ "kvm-intel" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Host identity
  networking.hostName = cfg.hostname;

  # ZFS requires unique hostId, generate randomly
  networking.hostId = cfg.hostId;

  # Static networking via systemd-networkd
  networking.useNetworkd = true;
  networking.useDHCP = false;

  # Use rescue OS to get NIC name and get IP config from console
  systemd.network.enable = true;
  systemd.network.networks."30-wan" = {
    matchConfig.Name = cfg.nicName;
    networkConfig.DHCP = "no";
    inherit (cfg) addresses routes;
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
