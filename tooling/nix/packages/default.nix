{
  myPython,
  pkgs,
  pyproject,
  root,
}:
let
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
  pythonProd = myPython.withPackages (p: [
    p.django
    p.django-htmx
    p.gunicorn
    p.psycopg2-binary
    p.htmx-examples
  ]);
  staticFiles = pkgs.stdenv.mkDerivation {
    pname = "${pyproject.project.name}-static";
    version = pyproject.project.version;
    src = root;
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
in
{
  inherit pythonProd;
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
        "${root}/docker-cmd.py"
      ];
      Env = [
        "DJANGO_SETTINGS_MODULE=htmx_examples.settings"
      ];
      ExposedPorts = {
        "8000/tcp" = { };
      };
    };
  };
  ci-tools = pkgs.buildEnv {
    name = "ci-tools";
    paths = [
      pkgs.skopeo
      pkgs.manifest-tool
    ];
    pathsToLink = [ "/bin" ];
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
}
