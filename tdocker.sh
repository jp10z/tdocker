#!/bin/bash

# main
main () {
    validate_action
    load_config_file_variables
    create_cache_folder
    validate_bin_docker_compose
    validate_compose_path
    validate_filter
    exec_action_up
    exec_action_down
    exec_action_autodown
}

# load config file variables
load_config_file_variables () {
    SELF_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
    CONFIG_PATH="$SELF_PATH/config.ini"
    if ! test -f "$CONFIG_PATH"; then
        return
    fi
    source $CONFIG_PATH
}
# create cache folder
create_cache_folder() {
    CACHE_PATH=("$SELF_PATH/cache/")
    script=("mkdir -p $CACHE_PATH")
    $script
}
# validate action
validate_action () {
    contains $ACTION "up down autodown"
    res=$?
    if [[ $res == "0" ]]; then
        echo "Invalid arg 1 ACTION $ACTION"
        exit 1
    fi
}
# validate docker-compose-bin
validate_bin_docker_compose () {
    if ! [ "${BIN_DOCKER_COMPOSE_PATH:0:1}" = "/" ]; then
        SELF_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
        BIN_DOCKER_COMPOSE_PATH="$SELF_PATH/$BIN_DOCKER_COMPOSE_PATH"
    fi
    if ! command -v $BIN_DOCKER_COMPOSE_PATH &> /dev/null; then
        echo "Docker compose bin not found: $BIN_DOCKER_COMPOSE_PATH"
        exit 1
    fi
}
# validate COMPOSE_PATH
validate_compose_path () {
    contains $ACTION "up down"
    if ! [ $? = "0" ]; then return; fi
    
    if ! [[ $COMPOSE_PATH == */ ]]; then
        COMPOSE_PATH="$COMPOSE_PATH/"
    fi
}
# validate filter
validate_filter () {
    if [ -z $FILTER ]; then return; fi
    contains $ACTION "up down"
    if [ $? = "1" ]; then
        filepath="$COMPOSE_PATH$FILTER.yml"
        if ! test -f "$filepath"; then
            echo "Compose file not found: $filepath"
            exit 1
        fi
    fi
}
# execute action configure
exec_configure () {
    if ! [ $ACTION = "configure" ]; then return; fi
    read_input "You want to configure docker-compose package? Y/N: " lower
    if [ $userinput == "y" ]; then
        read_input "Write the docker-compose binary path (empty to automatic): " lower
    fi
}
# execute action up
exec_action_up () {
    if ! [ $ACTION = "up" ]; then return; fi
    for compose_filepath in $COMPOSE_PATH$FILTER*.yml; do
        name=(${compose_filepath//./ })
        name=(${name/$COMPOSE_PATH/""})
        env_filepath="$ENV_PATH$name.env"
        if [ -f "$env_filepath" ]; then
            env_cmd="--env-file $env_filepath"
        fi
        echo ""
        echo "> Compose: $name"
        script=("$BIN_DOCKER_COMPOSE_PATH -f $compose_filepath $env_cmd -p $name pull")
        if ! [[ $DEBUG -eq "1" ]]; then
            $script
        else
            echo $script
        fi
        script=("$BIN_DOCKER_COMPOSE_PATH -f $compose_filepath $env_cmd -p $name up -d --remove-orphans")
        if ! [[ $DEBUG -eq "1" ]]; then
            $script
        else
            echo $script
        fi
        script=("cp -fr $compose_filepath $CACHE_PATH.")
        if ! [[ $DEBUG -eq "1" ]]; then
            $script
        else
            echo $script
        fi
    done
}
# execute action down
exec_action_down () {
    if ! [ $ACTION = "down" ]; then return; fi
    for compose_filepath in $COMPOSE_PATH$FILTER*.yml; do
        name=(${compose_filepath//./ })
        name=(${name/$COMPOSE_PATH/""})
        env_filepath="$ENV_PATH$name.env"
        if [ -f "$env_filepath" ]; then
            env_cmd="--env-file $env_filepath"
        fi
        echo ""
        echo "> Compose: $name"
        script=("$BIN_DOCKER_COMPOSE_PATH -f $compose_filepath $env_cmd -p $name down")
        if ! [[ $DEBUG -eq "1" ]]; then
            $script
        else
            echo $script
        fi
        script=("rm -f $CACHE_PATH$name.yml")
        if ! [[ $DEBUG -eq "1" ]]; then
            $script
        else
            echo $script
        fi
    done
}
# execute action autodown
exec_action_autodown () {
    if ! [ $ACTION = "autodown" ]; then return; fi
    active_composes=""
    for compose_filepath in $COMPOSE_PATH*.yml; do
        name=(${compose_filepath//./ })
        name=(${name/$COMPOSE_PATH/""})
        active_composes=("$active_composes$name ")
    done
    for compose_filepath in $CACHE_PATH*.yml; do
        name=(${compose_filepath//./ })
        name=(${name/$CACHE_PATH/""})
        contains $name "$active_composes"
        res=$?
        if [[ $res == "1" ]]; then
            continue
        fi
        echo ""
        echo "> Compose: $name"
        script=("$BIN_DOCKER_COMPOSE_PATH -f $compose_filepath $env_cmd -p $name down")
        if ! [[ $DEBUG -eq "1" ]]; then
            $script
        else
            echo $script
        fi
        script=("rm -f $CACHE_PATH$name.yml")
        if ! [[ $DEBUG -eq "1" ]]; then
            $script
        else
            echo $script
        fi
    done
}

# function to check if list contains a word
# $1: word
# $2: list of words
contains () {
    if [[ $2 =~ (^|[[:space:]])$1($|[[:space:]]) ]]; then
        return 1
    fi
    return 0
}
# function to read a input from user and convert
# $1: the prefix text of input
# $2: post process input [lower,upper]
read_input () {
    read -p "$1" userinput
    if [ $2 = "lower" ]; then
        userinput="${userinput,,}"
    fi
    if [ $2 = "upper" ]; then
        userinput="${userinput^^}"
    fi
}

ACTION=$1
FILTER=$2
main
echo ""