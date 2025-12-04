#!/usr/bin/env bash

DEVENV_ROOT=$(git rev-parse --show-toplevel)
DEVENV_STATE="$DEVENV_ROOT/.devenv/state"

_open_url() {
    url=$(_create_url)
    if [[ -n "${DEFAULT_BROWSER}" ]]; then
        $DEFAULT_BROWSER "$url"
    elif type explorer.exe &>/dev/null; then
        explorer.exe "$url"
    fi
}

_create_url() {
    if [ -f /etc/wsl.conf ]; then
        echo "http://localhost:$WEBPORT"
    else
        echo "http://$(hostname -f):$WEBPORT"
    fi
}
#}

# Main tasks start
declare -A tasks
declare -A descriptions

# Setup the database
setup() {
    sleep 5
    cd "$DEVENV_ROOT" || exit
    if [ -f .devenv/state/first_run ]; then
        ./src/manage.py collectstatic --noinput
        ./src/manage.py makemigrations
        ./src/manage.py migrate
    else
        ./src/manage.py collectstatic --noinput
        ./src/manage.py makemigrations
        ./src/manage.py migrate
        ./src/manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'password')"
    fi
    mkdir -p .devenv/state
    touch "$DEVENV_STATE"/first_run
    _open_url
}
descriptions["setup"]="Setup the database."
tasks["setup"]=setup

run() {
    cd "$DEVENV_ROOT" || exit
    mkdir --parents "$DEVENV_STATE"
    nix run .#process-compose
}
descriptions["run"]="Start the webserver."
tasks["run"]=run
descriptions["start"]="Alias for run."
tasks["start"]=run

reset() {
    find . \( -name __pycache__ -o -name "*.pyc" \) -delete
    rm -f "$DEVENV_STATE"/first_run
    rm -rf "$DEVENV_STATE"/postgres/
}
descriptions["reset"]="Reset the project to a fresh state including the database."
tasks["reset"]=reset

# only one task at a time
if [ $# != 1 ]; then
    printf "usage: dev <task_name>\n\n"
    for task in "${!tasks[@]}"; do
        echo "$task - ${descriptions[$task]}"
    done

else
    # Check if task is available
    if [[ -v "tasks[$1]" ]]; then
        ${tasks["$1"]}
    else
        echo "Task not found."
    fi
fi
