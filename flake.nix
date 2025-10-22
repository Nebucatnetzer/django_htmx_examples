{
  description = "A Python API for various tools I use at work.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv?ref=v1.8";
  };
  outputs =
    {
      self,
      nixpkgs,
      devenv,
      systems,
    }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
      });
      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pyproject = pkgs.lib.importTOML ./pyproject.toml;
          myPython = pkgs.python312.override {
            self = myPython;
            packageOverrides = pyfinal: pyprev: {
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
          pythonPod = myPython.withPackages (p: [
            p.django
            p.django-htmx
            p.gunicorn
            p.psycopg2-binary
          ]);
          pythonDev = myPython.withPackages (p: [
            p.black
            p.django
            p.django-htmx
            p.django-stubs
            p.docformatter
            p.gunicorn
            p.htmx-examples-editable
            p.isort
            p.mypy
            p.psycopg2-binary
            p.pylint
            p.pylint-django
            p.pylsp-mypy
            p.pytest
            p.pytest-cov
            p.pytest-django
            p.pytest-xdist
            p.python-lsp-ruff
            p.python-lsp-server
          ]);
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                packages = [
                  (pkgs.writeScriptBin "dev" "${builtins.readFile ./dev.sh}")
                  pythonDev
                ];
                env = {
                  DJANGO_SETTINGS_MODULE = "htmx_examples.settings";
                };
                process.implementation = "process-compose";
                process-managers.process-compose.enable = true;
                # https://github.com/cachix/devenv/blob/main/examples/process-compose/devenv.nix
                processes = {
                  webserver.exec = "$DEVENV_ROOT/src/manage.py runserver 0.0.0.0:8000";
                  setup.exec = "dev setup";
                };
                services.postgres = {
                  enable = true;
                  initialDatabases = [ { name = "django"; } ];
                  package = pkgs.postgresql_15;
                };
              }
            ];
          };
        }
      );
    };
}
