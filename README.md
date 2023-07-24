# django_htmx_examples

A collection of examples on how to do various tasks with HTMX and Django.

## Setup

There is currently only one supported way to work with this repository. You
will need a Linux system (WSL might work) onto wich you install the Nix package
manager with Flakes enabled[^1] and direnv[^3]. Afterwards you can enter the
development environment with `direnv allow`.

[^1]: https://nixos.org/download.html
[^3]: https://direnv.net/

After you've entered the development environment with either method you can
start the development server with `dev run`. This will start a PostgreSQL
database running and start the Django development server.

In case you want a fresh start or remove the project you can just remove the
`.direnv` and `.venv` directory at the root of the project. All the data of the
PostgreSQL database is stored there together with the symlinks to the Nix
store.

In case you want to tweak something these are the applications use do build the
development environment:

- Nix package manager
- direnv
- overmind[^4]

The `dev` command is a simple BASH script called `dev.sh` at the root of the
project.

[^4]: https://github.com/DarthSim/overmind

Run the `dev` command without an argument to see all options.

**Manual way**

The manual way you have to install poetry[^2] and then run `poetry shell` to
enter the virtual environment. You will then need a local PostgreSQL server or
modify the settings so that you can use your prefered database.

Please note that I will only use and test the first method.

[^2]: https://python-poetry.org
