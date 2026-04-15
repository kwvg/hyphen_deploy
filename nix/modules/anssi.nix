# Hardening based on ANSSI-BP-028-EN

{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machine;
in
{
  # R5–R8: Kernel command line hardening
  boot.kernelParams = [
    # R5: Disable kernel info leaks
    "quiet"
    "loglevel=3"

    # R7: IOMMU protection
    "iommu=force"
    "intel_iommu=on"

    # R8: Disable legacy interfaces
    "vsyscall=none"

    # Memory hardening (mostly commented out due to perf degradation with ZFS)
    "page_poison=1"
    # "slab_nomerge"
    # "slub_debug=FZP"
    # "init_on_alloc=1"
    # "init_on_free=1"

    # Spectre/Meltdown mitigations
    "spectre_v2=on"
    "spec_store_bypass_disable=on"
    "l1tf=full"
    "mds=full"

    # Lockdown mode (commented out due to conflict with NixOS)
    # "lockdown=integrity"

    # Randomize kernel stack offset
    "randomize_kstack_offset=on"

    # Disable debugfs
    "debugfs=off"
  ];

  # R10–R14: Kernel sysctl hardening
  boot.kernel.sysctl = {
    # R10: Restrict sysctl access
    "kernel.core_uses_pid" = 1;
    "kernel.sysrq" = 0;

    # R11: Restrict dmesg to root
    "kernel.dmesg_restrict" = 1;

    # R11: Restrict kernel pointers
    "kernel.kptr_restrict" = 2;

    # R11: Restrict perf access
    "kernel.perf_event_paranoid" = 3;

    # R14: Restrict ptrace scope
    "kernel.yama.ptrace_scope" = 1;

    # R14: Restrict unprivileged user namespaces
    "kernel.unprivileged_userns_clone" = 0;

    # R14: Restrict unprivileged BPF
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;

    # Appendix A: Restrict TTY handling
    "kernel.tiocsti_restrict" = 1;

    # Appendix A: Side channel mitigation
    "dev.tty.ldisc_autoload" = 0;

    # R12: IPv4 network hardening
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.all.log_martians" = 1;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.conf.all.secure_redirects" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    "net.ipv4.conf.default.log_martians" = 1;
    "net.ipv4.conf.default.rp_filter" = 1;
    "net.ipv4.conf.default.secure_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
    "net.ipv4.tcp_rfc1337" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_timestamps" = 0;

    # R13: IPv6 network hardening
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_source_route" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_source_route" = 0;

    # R52: Restrict named sockets and pipes
    "fs.protected_fifos" = 2;
    "fs.protected_hardlinks" = 1;
    "fs.protected_regular" = 2;
    "fs.protected_symlinks" = 1;

    # R54: Restrict core dumps
    "fs.suid_dumpable" = 0;

    # Prevent kernel image tampering
    "kernel.kexec_load_disabled" = 1;
  };

  # R10: Blacklist unused kernel modules
  boot.blacklistedKernelModules = [
    # Uncommon network protocols
    "af_802154"
    "appletalk"
    "atm"
    "ax25"
    "can"
    "dccp"
    "decnet"
    "econet"
    "ipx"
    "n-hdlc"
    "netrom"
    "p8022"
    "p8023"
    "psnap"
    "rds"
    "rose"
    "sctp"
    "tipc"
    "x25"

    # Uncommon filesystems
    "cramfs"
    "freevxfs"
    "hfs"
    "hfsplus"
    "jffs2"
    "udf"

    # [Server] Input devices
    "usbkbd"
    "usbmouse"

    # Firewire
    "firewire-core"
    "firewire-ohci"
    "firewire-sbp2"

    # Thunderbolt
    "thunderbolt"

    # Bluetooth
    "bluetooth"
    "btusb"

    # Wireless
    "cfg80211"
    "lib80211"
  ];

  # R28–R29: Filesystem mount hardening
  fileSystems."/boot" = {
    options = [
      "nodev"
      "noexec"
      "nosuid"
    ];
  };

  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "nodev"
      "noexec"
      "nosuid"
      "mode=1777"
      "size=2G"
    ];
  };

  # R36: UMASK 0027
  environment.sessionVariables.UMASK = "0027";
  security.loginDefs.settings = {
    UMASK = "0027";
    ENCRYPT_METHOD = "SHA512";
  };

  # R39–R43: Sudo hardening
  security.sudo = {
    execWheelOnly = true;
    extraConfig = ''
      Defaults !visiblepw
      Defaults env_reset
      Defaults logfile="/var/log/sudo.log"
      Defaults mail_badpass
      Defaults secure_path="/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin"
      Defaults timestamp_timeout=5
      Defaults use_pty
    '';
  };

  # R55: Dedicated temporary directories
  systemd.tmpfiles.rules = [
    "d /tmp 1777 root root 7d"
    "d /var/tmp 1777 root root 30d"
  ];

  # R62–R63: Disable unnecessary services
  networking.wireless.enable = false;
  services.avahi.enable = false;
  services.printing.enable = false;
  services.pulseaudio.enable = false;
  services.xserver.enable = false;

  # R67: SSH hardening
  services.openssh.settings = {
    AllowAgentForwarding = false;
    AllowTcpForwarding = false;
    Ciphers = [
      "chacha20-poly1305@openssh.com"
      "aes256-gcm@openssh.com"
      "aes128-gcm@openssh.com"
    ];
    ClientAliveCountMax = 2;
    ClientAliveInterval = 300;
    KexAlgorithms = [
      "curve25519-sha256"
      "curve25519-sha256@libssh.org"
      "diffie-hellman-group16-sha512"
      "diffie-hellman-group18-sha512"
    ];
    LoginGraceTime = 30;
    LogLevel = "VERBOSE";
    Macs = [
      "hmac-sha2-512-etm@openssh.com"
      "hmac-sha2-256-etm@openssh.com"
    ];
    MaxAuthTries = 3;
    MaxSessions = 2;
    PermitEmptyPasswords = false;
    X11Forwarding = false;
  };

  services.openssh.extraConfig = ''
    GSSAPIAuthentication no
    HostbasedAuthentication no
  '';

  # R71: Logging, journald with persistent storage
  services.journald = {
    extraConfig = ''
      Compress=yes
      ForwardToSyslog=no
      MaxRetentionSec=1month
      Storage=persistent
      SystemMaxUse=500M
    '';
  };

  # R73: Audit system
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      # Time changes
      "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change"
      "-a always,exit -F arch=b64 -S clock_settime -k time-change"
      "-w /etc/localtime -p wa -k time-change"

      # User/group changes
      "-w /etc/group -p wa -k identity"
      "-w /etc/gshadow -p wa -k identity"
      "-w /etc/passwd -p wa -k identity"
      "-w /etc/shadow -p wa -k identity"

      # Network changes
      "-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale"
      "-w /etc/hostname -p wa -k system-locale"
      "-w /etc/hosts -p wa -k system-locale"

      # Login/logout
      "-w /var/log/btmp -p wa -k logins"
      "-w /var/log/lastlog -p wa -k logins"
      "-w /var/log/wtmp -p wa -k logins"
      "-w /var/run/utmp -p wa -k session"

      # Sudo usage
      "-w /etc/sudoers -p wa -k scope"
      "-w /etc/sudoers.d/ -p wa -k scope"
      "-w /var/log/sudo.log -p wa -k actions"

      # Kernel module loading
      "-a always,exit -F arch=b64 -S finit_module -k modules"
      "-a always,exit -F arch=b64 -S init_module -S delete_module -k modules"

      # Mount operations
      "-a always,exit -F arch=b64 -S mount -S umount2 -k mounts"

      # File deletion
      "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete"

      # Privilege escalation
      "-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k privilege_escalation"

      # Make audit config immutable (commented out because error-prone)
      # "-e 2"
    ];
  };

  # R78–R80: Firewall hardening
  networking.firewall = {
    enable = true;
    logRefusedConnections = true;
    logRefusedPackets = true;
    pingLimit = "--limit 1/minute --limit-burst 5";
  };

  # R58: Strip default packages
  environment.defaultPackages = lib.mkForce [ ];

  # R64: Restrict /proc, hide other users' processes
  systemd.services."proc-hidepid" = {
    description = "Remount /proc with hidepid=2";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/mount -o remount,hidepid=2,gid=proc /proc";
      RemainAfterExit = true;
    };
  };
  users.groups.proc = { };
  users.users.${cfg.username}.extraGroups = lib.mkAfter [ "proc" ];

  # R56: Restrict core dumps
  security.pam.loginLimits = [
    {
      domain = "*";
      item = "core";
      type = "hard";
      value = "0";
    }
  ];
  systemd.coredump.extraConfig = ''
    Storage=none
    ProcessSizeMax=0
  '';

  # [Server] Disable USB storage
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEMS=="usb", DRIVERS=="usb-storage", ATTR{authorized}="0"
  '';

  # Restrict nix daemon
  nix.settings.allowed-users = [ "@wheel" ];

  # Restrict su to wheel group
  security.pam.services.su.requireWheel = true;
  security.pam.services.su-l.requireWheel = true;

  # Auto-update without reboot
  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
    dates = "04:00";
    flake = "/etc/nixos#${cfg.hostname}";
  };
}
