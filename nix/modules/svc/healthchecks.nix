# Ping healthchecks.io when both daemon and Web UI are active

{
  config,
  pkgs,
  ...
}:

let
  cfg = config.machine;
in
{
  systemd.services.healthcheck-ping = {
    description = "Ping healthchecks.io if nginx and API are healthy";
    after = [
      "network-online.target"
      "docker-portainer.service"
    ];
    wants = [ "network-online.target" ];
    path = [ pkgs.curl ];
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      set -u

      web_ret=$(curl -sf -o /dev/null -w "%{http_code}" -H "Host: ${cfg.healthcheckHost}" http://localhost:80/ || echo "000")
      svc_ret=$(curl -sf -o /dev/null -w "%{http_code}" -H "Host: ${cfg.healthcheckHost}" http://localhost:80/api/v1/status || echo "000")
      if [ "$web_ret" = "200" ] && [ "$svc_ret" = "200" ]; then
        curl -sf -o /dev/null https://hc-ping.com/${cfg.healthcheckUUID}
      else
        curl -sf -o /dev/null https://hc-ping.com/${cfg.healthcheckUUID}/fail
      fi
    '';
  };

  systemd.timers.healthcheck-ping = {
    description = "Ping healthchecks.io every 10 minutes";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*:0/10";
      Persistent = true;
    };
  };
}
