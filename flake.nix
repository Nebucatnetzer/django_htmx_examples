{
  description = "";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    {
      overlays.default = nixpkgs.lib.composeManyExtensions [
        poetry2nix.overlay
        (final: prev: rec {
          htmxDevEnv = prev.poetry2nix.mkPoetryEnv
            {
              projectDir = ./.;
              groups = [ "main" "dev" ];
            };
          htmxPackage = prev.poetry2nix.mkPoetryApplication {
            projectDir = ./.;
            groups = [ "main" ];
          };
          htmxEnv = htmxPackage.dependencyEnv;
        })
      ];
    } // (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      in
      rec {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.htmxDevEnv
            pkgs.poetry
            pkgs.python311
            pkgs.python311Packages.pip
            pkgs.overmind
            pkgs.postgresql_15
            (pkgs.writeScriptBin "dev" "${builtins.readFile ./dev.sh}")
          ];
          shellHook = ''
            export DJANGO_SETTINGS_MODULE=htmx_examples.settings
          '';
        };
      }));
}

