{ pkgs, ... }:
let
  start-postgres = import ./postgres.nix { inherit pkgs; };
in
pkgs.writeShellApplication {
  name = "process-compose";
  runtimeInputs = [
    pkgs.git
    pkgs.process-compose
    start-postgres
  ];
  text = ''
    DEVENV_ROOT=$(git rev-parse --show-toplevel)
    export DEVENV_ROOT
    process-compose -U --config ${./process-compose.yml} "$@"
  '';
}
