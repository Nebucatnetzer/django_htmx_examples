#!/usr/bin/env bash

# Helper functions not exposed to the user {

# Setup the database
_setup () {
    overmind start -l db -D
    sleep 2
    if [ -f .direnv/first_run ]; then
        python ./src/manage.py collectstatic --noinput
        python ./src/manage.py makemigrations
        python ./src/manage.py migrate
    else
        python ./src/manage.py collectstatic --noinput
        python ./src/manage.py makemigrations
        python ./src/manage.py migrate
        python ./src/manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'admin@example.com', 'password')"
        touch .direnv/first_run
    fi
    overmind quit
    sleep 2
}

_open_url () {
    if [[ ! -z "${DEFAULT_BROWSER}" ]]; then
        $DEFAULT_BROWSER $url
    elif type explorer.exe &> /dev/null; then
        explorer.exe $url
    fi
}

_create_url () {
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

run () {
    _setup
    url=$(_create_url)
    printf "\n---\n webserver: $url\n---\n"
    overmind start -D
    _open_url $url
}
descriptions["run"]="Start the webserver."
tasks["run"]=run
descriptions["start"]="Alias for run."
tasks["start"]=run

stop () {
    overmind quit
}
descriptions["stop"]="Stop the webserver and DB."
tasks["stop"]=stop

clean () {
    find . \( -name __pycache__ -o -name "*.pyc" \) -delete
    rm -f .direnv/first_run
    rm -f src/*/migrations/0*.py
    rm -rf .direnv/postgres/
    rm -rf .venv/
}
descriptions["clean"]="Reset the project to a fresh state including the database."
tasks["clean"]=clean


cleanall () {
    git clean -xdf
}
descriptions["cleanall"]="Completly remove any files which are not checked into git."
tasks["cleanall"]=cleanall

update (){
    poetry update --lock
}
descriptions["update"]="Update the dependencies."
tasks["update"]=update

# only one task at a time
if [ $# != 1 ]; then
    printf "usage: dev <task_name>\n\n"
    for task in "${!tasks[@]}"
    do
        echo "$task - ${descriptions[$task]}"
    done

else
    # Check if task is available
    if [[ -v "tasks[$1]" ]] ; then
        ${tasks["$1"]}
    else
        echo "Task not found."
    fi
fi
