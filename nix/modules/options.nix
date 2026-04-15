# Options definitions

{ lib, ... }:

{
  options.machine = {
    hostname = lib.mkOption { type = lib.types.str; };
    hostId = lib.mkOption { type = lib.types.str; };
    username = lib.mkOption { type = lib.types.str; };
    sshAuthorizedKeys = lib.mkOption { type = lib.types.listOf lib.types.str; };
    nicName = lib.mkOption { type = lib.types.str; };
    addresses = lib.mkOption { type = lib.types.listOf lib.types.str; };
    routes = lib.mkOption { type = lib.types.listOf lib.types.attrs; };
    healthcheckUUID = lib.mkOption { type = lib.types.str; };

    tunnels.ssh = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      hostname = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
    };

    tunnels.services = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            hostname = lib.mkOption { type = lib.types.str; };
            target = lib.mkOption { type = lib.types.str; };
          };
        }
      );
      default = { };
    };

    wireguard = {
      enabled = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      privateKeyFile = lib.mkOption {
        type = lib.types.str;
        default = "/etc/wireguard/private.key";
      };
      address = lib.mkOption {
        type = lib.types.str;
        default = "";
      };
      listenPort = lib.mkOption {
        type = lib.types.port;
        default = 51820;
      };
      peers = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              publicKey = lib.mkOption { type = lib.types.str; };
              endpoint = lib.mkOption { type = lib.types.str; };
              allowedIPs = lib.mkOption { type = lib.types.listOf lib.types.str; };
              persistentKeepalive = lib.mkOption {
                type = lib.types.int;
                default = 25;
              };
            };
          }
        );
        default = [ ];
      };
    };
  };
}
