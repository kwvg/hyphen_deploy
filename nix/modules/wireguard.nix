# WireGuard mesh
#
# Setup:
#   nix shell nixpkgs#wireguard-tools
#   sudo mkdir /etc/wireguard
#   umask 077 && wg genkey | sudo tee /etc/wireguard/private.key | wg pubkey

{
  config,
  lib,
  ...
}:

let
  cfg = config.machine;
  wgCfg = cfg.wireguard;
in
{
  config = lib.mkIf wgCfg.enabled {
    assertions = [
      {
        assertion = wgCfg.address != "";
        message = "machine.wireguard.address must be set when WireGuard is enabled";
      }
      {
        assertion = builtins.length wgCfg.peers > 0;
        message = "machine.wireguard.peers must have at least one entry when WireGuard is enabled";
      }
    ];

    # Loose reverse path filtering on wg0 to avoid ANSSI strict rp_filter dropping tunnel traffic
    boot.kernel.sysctl."net.ipv4.conf.wg0.rp_filter" = 2;

    # Bind sshd to the WireGuard address so peers can SSH over the tunnel
    services.openssh.listenAddresses = [
      {
        addr = builtins.head (lib.splitString "/" wgCfg.address);
        port = 22;
      }
    ];

    networking.firewall.trustedInterfaces = [ "wg0" ];
    networking.firewall.interfaces.${cfg.nicName}.allowedUDPPorts = [ wgCfg.listenPort ];
    networking.wireguard.interfaces.wg0 = {
      ips = [ wgCfg.address ];
      listenPort = wgCfg.listenPort;
      privateKeyFile = wgCfg.privateKeyFile;
      peers = map (p: {
        publicKey = p.publicKey;
        endpoint = p.endpoint;
        allowedIPs = p.allowedIPs;
        persistentKeepalive = p.persistentKeepalive;
      }) wgCfg.peers;
    };
  };
}
