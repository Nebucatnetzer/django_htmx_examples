{ myPython, WEBPORT, ... }:
{ config, pkgs, ... }:
let
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
  devShells.default = pkgs.mkShellNoCC {
    packages = [
      config.packages.dev-script
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
}
