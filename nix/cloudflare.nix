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

      # Apply IPv4
      for cidr in $v4; do
        iptables -A cloudflare -p tcp -s "$cidr" --dport 80 -j ACCEPT
        iptables -A cloudflare -p tcp -s "$cidr" --dport 443 -j ACCEPT
      done

      # Apply IPv6
      for cidr in $v6; do
        ip6tables -A cloudflare6 -p tcp -s "$cidr" --dport 80 -j ACCEPT
        ip6tables -A cloudflare6 -p tcp -s "$cidr" --dport 443 -j ACCEPT
      done

      # Drop non-Cloudflare traffic to 80/443
      iptables -A cloudflare-fwd -j DROP
      ip6tables -A cloudflare6-fwd -j DROP
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
