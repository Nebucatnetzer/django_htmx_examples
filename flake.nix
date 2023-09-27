{
  description = "";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils, poetry2nix }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
      in
      rec {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.poetry
            pkgs.python311
            pkgs.python311Packages.pip
            pkgs.overmind
            pkgs.postgresql_15
            (pkgs.writeScriptBin "dev" "${builtins.readFile ./dev.sh}")
          ];
          # Put the venv on the repo, so direnv can access it
          POETRY_VIRTUALENVS_IN_PROJECT = "true";
          # Use python from path, so you can use a different version to the one
          # bundled with poetry
          POETRY_VIRTUALENVS_PREFER_ACTIVE_PYTHON = "true";
          PYTHON_KEYRING_BACKEND = "keyring.backends.fail.Keyring";
          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc
            # Add any missing library needed You can use the nix-index package
            # to locate them, e.g.
            # nix-locate -w --top-level --at-root /lib/libudev.so.1
          ];
          shellHook = ''
            export DJANGO_SETTINGS_MODULE=htmx_examples.settings
          '';
        };
      }));
}

