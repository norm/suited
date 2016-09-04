#!/bin/bash
#
# FIXME introduction and documentation URL

# stop immediately on errors
set -e

SUITED_SH="$0"
REPO_TEST_CACHE=$( mktemp -d '/tmp/suited.repotest.XXXXX' )
CURL_TEMP_FILE=$( mktemp '/tmp/suited.curl.XXXXX' )
trap cleanup EXIT

# where to checkout github repos to? (defaults to "~/Code/user/repo")
REPO_DIR="${REPO_DIR:=${HOME}/Code}"

# where is homebrew installed?
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:=/usr/local}"

# hostname?
HOST="${HOST:=$(hostname -s)}"

# ANSI sequences
bold="\e[1m"
cyan="\e[36m"
yellow="\e[33m"
green="\e[32m"
magenta="\e[35m"
reset="\e[0m"

function action {
    printf "${green}=== ${1}${reset}\n" >&2
}

function status {
    printf "${cyan}--- ${1}${reset}\n" >&2
}

function error {
    printf "${bold}${magenta}*** ${1}${reset}\n" >&2
}

function debug {
    printf "${bold}${yellow}    ${1}${reset}\n" >&2
}

function cleanup {
    rm -rf $REPO_TEST_CACHE $CURL_TEMP_FILE
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

function resolve_public_github_url {
    local user=$( echo "$1" | awk -F/ '{ print $4 }' )
    local repo=$( echo "$1" | awk -F/ '{ print $5 }' )
    local base="https:..github.com.$user.$repo"
    local file=$( echo "$1" | sed -e "s/^${base}.//" )

    echo "https://raw.githubusercontent.com/$user/$repo/master/$file"
}

function resolve_private_github_url {
    local user=$( echo "$1" | awk -F/ '{ print $4 }' )
    local repo=$( echo "$1" | awk -F/ '{ print $5 }' )
    local base="https:..github.com.$user.$repo"
    local file=$( echo "$1" | sed -e "s/^${base}.//" )

    echo "https://api.github.com/repos/$user/$repo/contents/$file"
}

function is_public_repo {
    local repo="$1"

    # without a token, you can't see private repos anyway
    [ -z "$GITHUB_TOKEN" ] && \
        return 0

    local user=$( echo "$repo" | awk -F/ '{ print $4 }' )
    local name=$( echo "$repo" | awk -F/ '{ print $5 }' )
    local cache="$REPO_TEST_CACHE/$user.$name"

    [ -f "$cache.public" ] && \
        return 0
    [ -f "$cache.private" ] && \
        return 1

    curl -sH "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/repos/$user/$name \
            | grep -q 'private.*false'

    if [ $? == 0 ]; then
        touch "$cache.public"
        return 0
    fi

    touch "$cache.private"
    return 1
}

function fetch_url {
    local url="$1"
    local curlargs

    case "$1" in
        https://github.com/*)
            if is_public_repo "$1"; then
                url=$( resolve_public_github_url "$1" )
            else
                url=$( resolve_private_github_url "$1" )
                curlargs="-H 'Authorization: token $GITHUB_TOKEN' "
                curlargs="$curlargs -H 'Accept: application/vnd.github.v3.raw'"
            fi
            ;;

        *)  # use as-is
            ;;
    esac

    echo "$url"
    eval curl --fail --progress-bar $curlargs \
        "$url" > $CURL_TEMP_FILE
}

function process_brewfile {
    local brewfile=$( resolve_filename "$1" )
    local tempfile

    case "$brewfile" in
        http:*|https:*)
            # fetch a remote file and process it locally
            if url=$( fetch_url "$brewfile" ); then
                action "process remote brewfile '$brewfile'"
                brew bundle "--file=$CURL_TEMP_FILE"
            else
                error "cannot process '$url': curl failure"
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
    local destination="$2"
    local user=$( echo "$repo" | awk -F/ '{ print $1 }' )
    local name=$( echo "$repo" | awk -F/ '{ print $2 }' )

    if [ -z "$destination" ]; then
        destination="${REPO_DIR}/$user/$name"
    fi

    action "checkout '$repo' to $destination"

    if [ ! -d "$destination" ]; then
        mkdir -p "$destination"
        git clone git@github.com:${repo}.git "$destination"
        
        cd "$destination"

        [ -f Brewfile ] && \
            process_brewfile Brewfile
        [ -f script/bootstrap ] && \
            execute_shell_script script/bootstrap
    fi
}

function execute_shell_script {
    local script=$( resolve_filename "$1" )

    case "$script" in
        http:*|https:*)
            # fetch a remote file and process it locally
            if url=$( fetch_url "$script" ); then
                action "execute remote script '$script'"
                source "$CURL_TEMP_FILE"
            else
                error "cannot execute '$url': curl failure"
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

function process_root_suitfile {
    local suitfile="$1"

    BASE=$(dirname "$suitfile")
    process_suitfile $(basename "$suitfile")
}

function process_suitfile {
    local suitfile=$( resolve_filename "$1" )
    local filename
    local line
    local tempfile
    local usefile

    case "$1" in
        http:*|https:*|/*)
            # process absolute path suitfiles as a new root suitfile
            # (absolute paths reset BASE)
            $BASH $SUITED_SH "$1"
            return
            ;;
        *)  # do nothing
            ;;
    esac

    case "$suitfile" in
        http:*|https:*)
            # fetch a remote file and process it locally
            if url=$( fetch_url "$suitfile" ); then
                action "process remote suitfile '$suitfile'"
                usefile=$CURL_TEMP_FILE
            else
                error "cannot process '$url': curl failure"
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
                local repo=$(
                    echo "$line" \
                        | awk '{ print $1 }' \
                        | sed -e 's/^github://'
                )
                local destination=$(
                    echo "$line" \
                        | awk '{ print $2 }' \
                        | sed -e "s:~:${HOME}:"
                )
                checkout_github_repo $repo "$destination"
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
[ -z "$IN_SUITED" ] && \
    echo "Checking you can sudo, enter password if prompted..."

sudo -v || {
    echo "suited.sh needs sudo access"
    exit 1
}

export IN_SUITED=1
for file in "$@"; do
    process_root_suitfile "$file"
done
