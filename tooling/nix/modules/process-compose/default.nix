{ servicesFlake, WEBPORT, ... }:
{ config, ... }:
{
  process-compose."dev-services" = {
    imports = [
      servicesFlake
      ./services.nix
    ];
    cli = {
      # environment.PC_DISABLE_TUI = true;
      # Global options for `process-compose`
      options = {
        no-server = true;
      };
    };
    settings = {
      processes = {
        webserver = {
          # process-compose.depends_on.setup.condition = "process_completed_successfully";
          command = "$DEVENV_ROOT/src/manage.py runserver 0.0.0.0:${builtins.toString WEBPORT}";
        };
        setup = {
          # process-compose.depends_on.postgres.condition = "process_started";
          command = "${config.packages.dev-script}/bin/dev setup";
        };
      };
    };
  };
}
