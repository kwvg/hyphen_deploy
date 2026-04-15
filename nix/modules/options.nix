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
  };
}
