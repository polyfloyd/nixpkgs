{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.woodpecker-agents;

  agentModule = lib.types.submodule {
    options = {
      enable = lib.mkEnableOption "this Woodpecker-Agent. Agents execute tasks generated by a Server, every install will need one server and at least one agent";

      package = lib.mkPackageOption pkgs "woodpecker-agent" { };

      environment = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.str;
        example = lib.literalExpression ''
          {
            WOODPECKER_SERVER = "localhost:9000";
            WOODPECKER_BACKEND = "docker";
            DOCKER_HOST = "unix:///run/podman/podman.sock";
          }
        '';
        description = "woodpecker-agent config environment variables, for other options read the [documentation](https://woodpecker-ci.org/docs/administration/agent-config)";
      };

      extraGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "podman" ];
        description = ''
          Additional groups for the systemd service.
        '';
      };

      path = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = [ "" ];
        description = ''
          Additional packages that should be added to the agent's `PATH`.
          Mostly useful for the `local` backend.
        '';
      };

      environmentFile = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [ ];
        example = [ "/var/secrets/woodpecker-agent.env" ];
        description = ''
          File to load environment variables
          from. This is helpful for specifying secrets.
          Example content of environmentFile:
          ```
          WOODPECKER_AGENT_SECRET=your-shared-secret-goes-here
          ```
        '';
      };
    };
  };

  mkAgentService = name: agentCfg: {
    name = "woodpecker-agent-${name}";
    value = {
      description = "Woodpecker-Agent Service - ${name}";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        DynamicUser = true;
        SupplementaryGroups = agentCfg.extraGroups;
        EnvironmentFile = agentCfg.environmentFile;
        ExecStart = lib.getExe agentCfg.package;
        Restart = "on-failure";
        RestartSec = 15;
        CapabilityBoundingSet = "";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateUsers = true;
        ProtectHostname = true;
        ProtectClock = true;
        ProtectKernelTunables = true;
        ProtectKernelModules = true;
        ProtectKernelLogs = true;
        ProtectControlGroups = true;
        RestrictAddressFamilies = [ "AF_UNIX AF_INET AF_INET6" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        PrivateMounts = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = "~@clock @privileged @cpu-emulation @debug @keyring @module @mount @obsolete @raw-io @reboot @setuid @swap";
        BindReadOnlyPaths = [
          "-/etc/resolv.conf"
          "-/etc/nsswitch.conf"
          "-/etc/ssl/certs"
          "-/etc/static/ssl/certs"
          "-/etc/hosts"
          "-/etc/localtime"
        ];
      };
      inherit (agentCfg) environment path;
    };
  };
in
{
  meta.maintainers = with lib.maintainers; [ ambroisie ];

  options = {
    services.woodpecker-agents = {
      agents = lib.mkOption {
        default = { };
        type = lib.types.attrsOf agentModule;
        example = lib.literalExpression ''
          {
            podman = {
              environment = {
                WOODPECKER_SERVER = "localhost:9000";
                WOODPECKER_BACKEND = "docker";
                DOCKER_HOST = "unix:///run/podman/podman.sock";
              };

              extraGroups = [ "podman" ];

              environmentFile = [ "/run/secrets/woodpecker/agent-secret.txt" ];
            };

            exec = {
              environment = {
                WOODPECKER_SERVER = "localhost:9000";
                WOODPECKER_BACKEND = "local";
              };

              environmentFile = [ "/run/secrets/woodpecker/agent-secret.txt" ];

              path = [
                # Needed to clone repos
                git
                git-lfs
                woodpecker-plugin-git
                # Used by the runner as the default shell
                bash
                # Most likely to be used in pipeline definitions
                coreutils
              ];
            };
          }
        '';
        description = "woodpecker-agents configurations";
      };
    };
  };

  config = {
    systemd.services =
      let
        mkServices = lib.mapAttrs' mkAgentService;
        enabledAgents = lib.filterAttrs (_: agent: agent.enable) cfg.agents;
      in
      mkServices enabledAgents;
  };
}
