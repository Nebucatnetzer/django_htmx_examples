{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nix-libs.url = "git+ssh://git@git.2li.ch/Nebucatnetzer/nix-libs.git";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };
  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.process-compose-flake.flakeModule
        inputs.nix-libs.lib.pkgs-ouput
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        { pkgs, ... }:
        let
          myPython = pkgs.python3.override {
            self = myPython;
            packageOverrides = pyfinal: _pyprev: {
              htmx-examples = pyfinal.buildPythonPackage {
                pname = "htmx-examples";
                inherit (pyproject.project) version;
                pyproject = true;
                src = ./.;
                propagatedBuildInputs = [ pyfinal.hatchling ];
              };
              # An editable package with a script that loads our mutable location
              htmx-examples-editable = pyfinal.mkPythonEditablePackage {
                # Inherit project metadata from pyproject.toml
                pname = pyproject.project.name;
                inherit (pyproject.project) version;
                # The editable root passed as a string
                root = "$DEVENV_ROOT/src"; # Use environment variable expansion at runtime
              };
            };
          };
          pyproject = pkgs.lib.importTOML ./pyproject.toml;
          WEBPORT = 8080;
        in
        {
          imports = [
            (import ./tooling/nix/modules/dev_shell.nix { inherit myPython WEBPORT; })
            (import ./tooling/nix/modules/packages { inherit myPython pyproject; })
            (import ./tooling/nix/modules/process-compose {
              servicesFlake = inputs.services-flake.processComposeModules.default;
              inherit WEBPORT;
            })
          ];
        };
    };
}
