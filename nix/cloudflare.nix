# Allow HTTP(S) only from Cloudflare IPs, refreshed daily

{
  pkgs,
  ...
}:

{
  systemd.services.cloudflare-firewall = {
    description = "Allow HTTP(S) only from Cloudflare origin addresses";
    after = [
      "network-online.target"
      "firewall.service"
      "docker.service"
    ];
    wants = [ "network-online.target" ];
    bindsTo = [ "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    path = with pkgs; [
      iptables
      curl
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -u

      # Fetch Cloudflare IP ranges. On failure, drop all web traffic rather than leaving the origin exposed.
      v4=$(curl -sf https://www.cloudflare.com/ips-v4/) || v4=""
      v6=$(curl -sf https://www.cloudflare.com/ips-v6/) || v6=""

      # Remove all jumps to our INPUT chains (handles any previous rule signature)
      while iptables -D nixos-fw -j cloudflare 2>/dev/null; do :; done
      while ip6tables -D nixos-fw -j cloudflare6 2>/dev/null; do :; done

      # Create or flush INPUT chains
      iptables -N cloudflare 2>/dev/null || iptables -F cloudflare
      ip6tables -N cloudflare6 2>/dev/null || ip6tables -F cloudflare6

      # Allow loopback
      iptables -A cloudflare -i lo -j ACCEPT
      ip6tables -A cloudflare6 -i lo -j ACCEPT

      # Apply IPv4 INPUT rules
      for cidr in $v4; do
        iptables -A cloudflare -p tcp -s "$cidr" -j ACCEPT
      done

      # Apply IPv6 INPUT rules
      for cidr in $v6; do
        ip6tables -A cloudflare6 -p tcp -s "$cidr" -j ACCEPT
      done

      # Drop non-Cloudflare traffic
      iptables -A cloudflare -j DROP
      ip6tables -A cloudflare6 -j DROP

      # Jump into INPUT chains from nixos-fw (only for 80/443)
      iptables -I nixos-fw -p tcp --dport 80 -j cloudflare
      iptables -I nixos-fw -p tcp --dport 443 -j cloudflare
      ip6tables -I nixos-fw -p tcp --dport 80 -j cloudflare6
      ip6tables -I nixos-fw -p tcp --dport 443 -j cloudflare6

      # Remove all jumps to our FORWARD chains (handles any previous rule signature)
      while iptables -D DOCKER-USER -j cloudflare-fwd 2>/dev/null; do :; done
      while ip6tables -D DOCKER-USER -j cloudflare6-fwd 2>/dev/null; do :; done

      # Create or flush FORWARD chains
      iptables -N cloudflare-fwd 2>/dev/null || iptables -F cloudflare-fwd
      ip6tables -N cloudflare6-fwd 2>/dev/null || ip6tables -F cloudflare6-fwd

      # Apply IPv4 FORWARD rules
      for cidr in $v4; do
        iptables -A cloudflare-fwd -p tcp -s "$cidr" --dport 80 -j RETURN
        iptables -A cloudflare-fwd -p tcp -s "$cidr" --dport 443 -j RETURN
      done

      # Apply IPv6 FORWARD rules
      for cidr in $v6; do
        ip6tables -A cloudflare6-fwd -p tcp -s "$cidr" --dport 80 -j RETURN
        ip6tables -A cloudflare6-fwd -p tcp -s "$cidr" --dport 443 -j RETURN
      done

      # Drop non-Cloudflare traffic to 80/443
      iptables -A cloudflare-fwd -j DROP
      ip6tables -A cloudflare6-fwd -j DROP

      # Only jump into the chain for inbound traffic to 80/443 from the
      # physical NIC. Outbound, inter-container, and other ports skip it.
      iptables -I DOCKER-USER -i enp0s31f6 -p tcp --dport 80 -j cloudflare-fwd
      iptables -I DOCKER-USER -i enp0s31f6 -p tcp --dport 443 -j cloudflare-fwd
      ip6tables -I DOCKER-USER -i enp0s31f6 -p tcp --dport 80 -j cloudflare6-fwd
      ip6tables -I DOCKER-USER -i enp0s31f6 -p tcp --dport 443 -j cloudflare6-fwd
    '';
  };

  systemd.timers.cloudflare-firewall = {
    description = "Refresh Cloudflare origin addresses";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
