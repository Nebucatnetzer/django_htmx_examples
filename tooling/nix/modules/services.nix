{ pkgs, ... }:
{
  services.postgres."htmx-db" = {
    dataDir = "$DEVENV_STATE/postgres/htmx-db";
    enable = true;
    initialDatabases = [ { name = "django"; } ];
    package = pkgs.postgresql_15;
  };
}
