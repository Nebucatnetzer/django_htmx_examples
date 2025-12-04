{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    { ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = inputs.nixpkgs.legacyPackages."x86_64-linux";
      myPython = pkgs.python3.override {
        self = myPython;
        packageOverrides = pyfinal: _pyprev: {
          htmx-examples = pyfinal.buildPythonPackage {
            pname = "htmx-examples";
            inherit (pyproject.project) version;
            pyproject = true;
            src = root;
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
      # TODO: filter root so that it only contains the relevant files.
      root = ./.;
    in
    {
      devShells."${system}".default = import ./tooling/nix/dev_shell { inherit myPython pkgs; };
      packages."${system}" = {
        inherit
          (import ./tooling/nix/packages {
            inherit
              myPython
              pyproject
              pkgs
              root
              ;
          })
          app-image
          ci-tools
          nginx-image
          ;
        process-compose = import ./tooling/nix/dev_shell/process-compose {
          inherit myPython pkgs;
        };
      };
    };
}
