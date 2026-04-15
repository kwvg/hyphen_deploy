# General configuration

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machine;
  docker-buildx = pkgs.fetchurl {
    url = "https://github.com/docker/buildx/releases/download/v0.21.2/buildx-v0.21.2.linux-amd64";
    hash = "sha256-gM5DM1Z2JsWzeHW7E/GGn0pEwxu8bhh15hOCkozo7nQ=";
    executable = true;
    name = "docker-buildx";
  };
in
{
  imports = [
    ./anssi.nix
    ./svc/cloudflare.nix
    ./svc/healthchecks.nix
    ./disko-config.nix
    ./hetzner.nix
    ./tunnel.nix
    ./wireguard.nix
  ];

  system.stateVersion = "25.05";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  programs.command-not-found.enable = false;
  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  # Boot
  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "md_mod"
        "nvme"
        "raid1"
        "sd_mod"
        "sr_mod"
        "xhci_pci"
      ];
      kernelModules = [ "zfs" ];
    };
    kernelParams = [
      "zfs.zfs_arc_max=${toString (24 * 1024 * 1024 * 1024)}"
      "delayacct"
    ];
    loader.grub.enable = true;
    supportedFilesystems = [ "zfs" ];
    swraid = {
      enable = true;
      mdadmConf = "MAILADDR root";
    };
    zfs.devNodes = "/dev/disk/by-id";
  };

  # Locale and time
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "UTC";

  # Packages and shell
  environment.systemPackages = with pkgs; [
    backblaze-b2
    clang
    cloudflared
    docker-compose
    fishPlugins.bobthefish
    git
    htop
    iotop
    nano
    postgresql_18
    rar
    rsync
    rustup
    tmux
    zstd
  ];
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "rar"
    ];
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # bobthefish: beloglazov theme
      set -g theme_color_scheme beloglazov
      set -g theme_display_git yes
      set -g theme_display_git_dirty yes
      set -g theme_display_hostname ssh
      set -g theme_display_user ssh
      set -g theme_nerd_fonts no
      set -g theme_powerline_fonts no
    '';
  };

  # Users
  users.users = {
    root.hashedPassword = "!";
    ${cfg.username} = {
      isNormalUser = true;
      uid = 1000;
      group = cfg.username;
      extraGroups = [
        "wheel"
        "docker"
      ];
      shell = pkgs.fish;
      home = "/home/${cfg.username}";
      openssh.authorizedKeys.keys = cfg.sshAuthorizedKeys;
    };
  };
  users.groups = {
    ${cfg.username} = {
      gid = 1000;
    };
  };
  security.sudo.wheelNeedsPassword = false;

  # Services
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  services.postgresql.enable = false;

  # No swap
  swapDevices = [ ];

  # Docker with overlay2 to avoid trashing ZFS
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    storageDriver = "overlay2";
    daemon.settings = {
      no-new-privileges = true;
      icc = true;
      live-restore = true;
      userland-proxy = true;
      log-driver = "journald";
    };
  };

  # Portainer CE
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers.portainer = {
    image = "portainer/portainer-ce:latest";
    ports = [ "127.0.0.1:9000:9000" ];
    volumes = [
      "/home/${cfg.username}:/home/${cfg.username}"
      "/srv/cluster128k/portainer:/data"
      "${docker-buildx}:/usr/local/lib/docker/cli-plugins/docker-buildx:ro"
      "/var/run/docker.sock:/var/run/docker.sock"
    ];
  };

  # Firewall
  networking.firewall = {
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];
  };
}
