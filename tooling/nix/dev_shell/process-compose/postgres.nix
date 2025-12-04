{ pkgs, ... }:
let
  hbaConfigFile = pkgs.writeText "pg_hba.conf" (builtins.readFile ./pg_hba.conf);
  postgresConfig = pkgs.writeText "postgresql.conf" ''
    ${builtins.readFile ./postgresql.conf}
    hba_file = '${hbaConfigFile}'
  '';
in
pkgs.writeShellApplication {
  name = "start-postgres";
  runtimeInputs = [
    pkgs.postgresql_15
  ];
  text = ''
    PGDATA="$DEVENV_STATE/postgres"
    export PGDATA

    if [[ ! -d "$PGDATA" ]]; then
      initdb --locale=C --encoding=UTF8

      cp -f ${postgresConfig} "$PGDATA/postgresql.conf"
      pg_ctl -D "$PGDATA" -w start
      echo 'create database "django";' | psql -v "ON_ERROR_STOP=1" "$@" -d postgres
      pg_ctl -D "$PGDATA" -m fast -w stop
    fi

    postgres
  '';
}
