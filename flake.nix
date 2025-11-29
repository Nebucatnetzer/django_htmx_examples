{
  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };
  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.process-compose-flake.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        { pkgs, ... }:
        let
          devScript = pkgs.writeScriptBin "dev" "${builtins.readFile ./tooling/bin/dev.sh}";
          nginxConfig = pkgs.writeText "nginx.conf" ''
            user nobody nobody;
            daemon off;
            error_log /dev/stdout info;
            pid /dev/null;
            worker_processes auto;
            events {}
            http {
                types_hash_max_size 4096;
                include ${pkgs.mailcap}/etc/nginx/mime.types;
                upstream app {
                    server zweili-search-app:8000;
                }

                server {
                    listen 80;
                    location / {
                        proxy_pass http://app;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_set_header Host $host;
                        proxy_redirect off;
                    }

                    location /static/ {
                        alias ${staticFiles}/static/;
                    }
                }
            }
          '';
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
          pythonProd = myPython.withPackages (p: [
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
          pyproject = pkgs.lib.importTOML ./pyproject.toml;
          staticFiles = pkgs.stdenv.mkDerivation {
            pname = "${pyproject.project.name}-static";
            version = pyproject.project.version;
            src = ./.;
            buildPhase = ''
              export HTMX_EXAMPLES_DB_DIR="$out"
              export DJANGO_SETTINGS_MODULE=htmx_examples.settings
              export MEDIA_ROOT=/dev/null
              export SECRET_KEY=dummy
              export DATABASE_URL=sqlite://:memory:
              ${pythonProd.interpreter} -m django collectstatic --noinput
            '';
            phases = [ "buildPhase" ];
          };
          WEBPORT = 8080;
        in
        {
          packages = {
            inherit pythonProd;
            ci-tools = pkgs.buildEnv {
              name = "ci-tools";
              paths = [
                pkgs.skopeo
                pkgs.manifest-tool
              ];
              pathsToLink = [ "/bin" ];
            };
            app-image = pkgs.dockerTools.buildImage {
              name = "htmx-example-app";
              tag = "latest";
              architecture = "linux/arm64";
              copyToRoot = pkgs.buildEnv {
                name = "image-root";
                paths = [
                  pythonProd
                ];
              };
              config = {
                Cmd = [
                  "${pythonProd.interpreter}"
                  ./docker-cmd.py
                ];
                Env = [
                  "DJANGO_SETTINGS_MODULE=htmx_examples.settings"
                ];
                ExposedPorts = {
                  "8000/tcp" = { };
                };
              };
            };
            nginx-image = pkgs.dockerTools.buildLayeredImage {
              name = "htmx-example-nginx";
              tag = "latest";
              contents = [
                pkgs.fakeNss
                pkgs.nginx
              ];

              extraCommands = ''
                mkdir -p tmp/nginx_client_body

                # nginx still tries to read this directory even if error_log
                # directive is specifying another file :/
                mkdir -p var/log/nginx
              '';

              config = {
                Cmd = [
                  "nginx"
                  "-c"
                  nginxConfig
                ];
                ExposedPorts = {
                  "80/tcp" = { };
                };
              };
            };
          };
          process-compose."dev-services" = {
            imports = [
              inputs.services-flake.processComposeModules.default
              ./tooling/nix/modules/services.nix
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
                  command = "${devScript}/bin/dev setup";
                };
              };
            };
          };
          devShells.default = pkgs.mkShellNoCC {
            packages = [
              devScript
              pythonDev
              pkgs.deadnix
              pkgs.nixfmt-rfc-style
            ];
            env = {
              DJANGO_SETTINGS_MODULE = "htmx_examples.settings";
              SECRET_KEY = "foo";
              PGHOST = "localhost";
              PGPORT = 5432;
              inherit WEBPORT;
            };
            shellHook = ''
              export DEVENV_ROOT=$(git rev-parse --show-toplevel)
              export DEVENV_STATE="$DEVENV_ROOT/.devenv/state"
              export HTMX_EXAMPLES_DB_DIR="$DEVENV_STATE/htmx_db"
              mkdir -p $DEVENV_STATE
            '';
          };
        };
    };
}
