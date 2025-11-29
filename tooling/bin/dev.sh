#!/usr/bin/env bash

# Helper functions not exposed to the user {

_open_url() {
    if [[ ! -z "${DEFAULT_BROWSER}" ]]; then
        $DEFAULT_BROWSER $url
    elif type explorer.exe &>/dev/null; then
        explorer.exe $url
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
    pushd $(pwd)
    cd $DEVENV_ROOT
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
    touch .devenv/state/first_run
    popd
}
descriptions["setup"]="Setup the database."
tasks["setup"]=setup

run() {
    process-compose up
}
descriptions["run"]="Start the webserver."
tasks["run"]=run
descriptions["start"]="Alias for run."
tasks["start"]=run

clean() {
    find . \( -name __pycache__ -o -name "*.pyc" \) -delete
    rm -f .direnv/first_run
    rm -f src/*/migrations/0*.py
    rm -rf .direnv/postgres/
    rm -rf .venv/
}
descriptions["clean"]="Reset the project to a fresh state including the database."
tasks["clean"]=clean

cleanall() {
    git clean -xdf
}
descriptions["cleanall"]="Completly remove any files which are not checked into git."
tasks["cleanall"]=cleanall

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
