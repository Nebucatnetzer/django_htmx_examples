{
  description = "";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }: (flake-utils.lib.eachDefaultSystem (system:
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
        PYTHON_KEYRING_BACKEND = "keyring.backends.fail.Keyring";
        LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
        shellHook = ''
          export DJANGO_SETTINGS_MODULE=htmx_examples.settings
        '';
      };
    }));
}

