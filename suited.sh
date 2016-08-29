#!/bin/bash
#
# FIXME introduction and documentation URL

# stop immediately on errors
set -e

# where to checkout github repos to? (defaults to "~/Code/user/repo")
REPO_DIR="${REPO_DIR:=${HOME}/Code}"

# where is homebrew installed?
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:=/usr/local}"

# hostname?
HOST="${HOST:=$(hostname -s)}"

# ANSI sequences
bold="\e[1m"
cyan="\e[36m"
green="\e[32m"
magenta="\e[35m"
reset="\e[0m"

function action {
    printf "${green}=== ${1}${reset}\n"
}

function status {
    printf "${cyan}--- ${1}${reset}\n"
}

function error {
    printf "${bold}${magenta}--- ${1}${reset}\n"
}

function accept_xcode_license {
    if /usr/bin/xcrun clang 2>&1 | grep license; then
        status 'need to accept the Xcode license'
        sudo xcodebuild -license
    fi
}

function resolve_filename {
    local suitfile="$1"

    case "$suitfile" in
        http:*|https:*)
            # absolute url
            echo $suitfile
            ;;

        /*) # absolute path
            echo $suitfile
            ;;

        *)  # relative to the base
            echo "${BASE}/${suitfile}"
            ;;
    esac
}

function process_brewfile {
    local brewfile=$( resolve_filename "$1" )
    local tempfile

    case "$brewfile" in
        http:*|https:*)
            # fetch a remote file and process it locally
            tempfile=$( mktemp '/tmp/suited.file.XXXXXX' )
            curl --progress-bar --fail "$brewfile" > "$tempfile"
            if [ $? == 0 ]; then
                action "process remote brewfile '$brewfile'"
                brew bundle "--file=$tempfile"
                rm -f "$tempfile"
            else
                error "cannot process '$brewfile': curl failure"
                return 1
            fi
            ;;

        *)  # process a local file
            if [ -f "$brewfile" ]; then
                action "process local brewfile '$brewfile'"
                brew bundle "--file=$brewfile"
            else
                error "cannot process '$brewfile': does not exist"
                return 1
            fi
            ;;
    esac
}

function checkout_github_repo {
    local repo="$1"
    local user=$( echo "$repo" | awk -F/ '{ print $1 }' )
    local name=$( echo "$repo" | awk -F/ '{ print $2 }' )

    action "checkout '$repo'"

    mkdir -p "$REPO_DIR/$user"
    pushd "$REPO_DIR/$user" >/dev/null  # unnecessarily noisy

    if [ ! -d $name ]; then
        git clone git@github.com:${repo}.git
    fi

    cd $name

    [ -f Brewfile ] && \
        process_brewfile "$REPO_DIR/$repo/Brewfile"
    [ -f scripts/bootstrap ] && \
        execute_shell_script "$REPO_DIR/$repo/scripts/bootstrap"

    popd >/dev/null  # unnecessarily noisy
}

function execute_shell_script {
    local script=$( resolve_filename "$1" )

    case "$script" in
        http:*|https:*)
            # fetch a remote file and process it locally
            tempfile=$( mktemp '/tmp/suited.file.XXXXXX' )
            curl --progress-bar --fail "$script" > "$tempfile"
            if [ $? == 0 ]; then
                action "execute remote script '$script'"
                source "$tempfile"
                rm -f "$tempfile"
            else
                error "cannot execute '$script': curl failure"
                return 1
            fi
            ;;

        *)  # process a local file
            if [ -f "$script" ]; then
                action "execute local script '$script'"
                source "$script"
            else
                error "cannot execute '$script': does not exist"
                return 1
            fi
            ;;
    esac
}

function process_line {
    local line="$1"
    local filename

    line=$(
        echo "$line" | \
            sed -e "s/\$USER/$USER/g" \
                -e "s/\$HOST/$HOST/g" \
                -e "s/\$GITHUB_USER/$GITHUB_USER/g"
    )
    filename=$( basename "$line" | tr 'A-Z' 'a-z' )

    if [ "$filename" == 'brewfile' ]; then
        process_brewfile "$line"
    elif [[ "$filename" == *.sh ]]; then
        execute_shell_script "$line"
    else
        process_suitfile "$line"
    fi
}

function process_suitfile {
    local suitfile=$( resolve_filename "$1" )
    local filename
    local line
    local tempfile
    local usefile

    case "$suitfile" in
        http:*|https:*)
            # fetch a remote file and process it locally
            tempfile=$( mktemp '/tmp/suited.file.XXXXXX' )
            curl --progress-bar --fail "$suitfile" > "$tempfile"
            if [ $? == 0 ]; then
                action "process remote suitfile '$suitfile'"
                usefile="$tempfile"
            else
                error "cannot process '$suitfile': curl failure"
                return 1
            fi
            ;;

        *)  # process a local file
            if [ -f "$suitfile" ]; then
                action "process local suitfile '$suitfile'"
                usefile="$suitfile"
            else
                error "cannot process '$suitfile': does not exist"
                return 1
            fi
            ;;
    esac

    IFS=$'\n'
    for line in $( cat "$usefile" ); do
        # trim whitespace
        line=$( echo "$line" | sed -e 's/^ *//' -e 's/ *$//' )

        case "$line" in
            \#*)
                # commented line, ignore
                ;;

            github:*)
                # checkout a repo and initialise it
                local repo=$( echo "$line" | sed -e 's/^github://' )
                checkout_github_repo "$repo"
                echo ''
                ;;

            *)  process_line "$line"
                ;;
        esac
    done

    [ -n "$tempfile" ] && \
        rm -f "$tempfile"
    return 0
}


# first, check we can sudo
echo "Checking you can sudo..."
sudo -v || {
    echo "suited.sh needs sudo access"
    exit 1
}

# what is the base location for finding files?
# command-line takes precedence over environment, environment over default
BASE="${BASE:=.}"
[ -n "$1" ] && \
    BASE="$1"

process_suitfile "main.conf"
