#!/bin/bash
#
# FIXME introduction and documentation URL

# stop immediately on errors
set -e

SUITED_SH="$0"
REPO_TEST_CACHE=$( mktemp -d '/tmp/suited.repotest.XXXXX' )
CURL_TEMP_FILE=$( mktemp '/tmp/suited.curl.XXXXX' )
STDIN_TEMP_FILE=$( mktemp 'suited.stdin.XXXXX' )
INFO_TEMP_FILE=$( mktemp '/tmp/suited.info.XXXXX' )
DEBUG=0
trap cleanup EXIT

while getopts "d" option; do
    case $option in
        d)  DEBUG=1;;
    esac
done
shift $(( OPTIND - 1 ))

# where to clone repos to? (defaults to "~/Code/user/repo")
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
    [ $DEBUG -eq 1 ] && \
        printf "${bold}${yellow}    ${1}${reset}\n" >&2
}

function cleanup {
    local info_length=$(
        wc -l $INFO_TEMP_FILE \
            | awk '{ print $1 }' \
            | sed -e 's/ //g'
    )

    if [ "$info_length" -gt 0 ]; then
        echo ''
        action "Post-install information:"
        cat $INFO_TEMP_FILE
    fi

    rm -rf $REPO_TEST_CACHE $CURL_TEMP_FILE $INFO_TEMP_FILE $STDIN_TEMP_FILE
}

function accept_xcode_license {
    if /usr/bin/xcrun clang 2>&1 | grep license; then
        status 'need to accept the Xcode license'
        sudo xcodebuild -license
    fi
}

function add_to_bash_profile {
    if [ -f ${HOME}/.bash_profile.suited ]; then
        cat >> ${HOME}/.bash_profile.suited
    else
        cat >> ${HOME}/.bash_profile
    fi
}

function add_to_bashrc {
    if [ -f ${HOME}/.bashrc.suited ]; then
        cat >> ${HOME}/.bashrc.suited
    else
        cat >> ${HOME}/.bashrc
    fi
}

function inform {
    if [ -n "$@" ]; then
        echo "$@" >> $INFO_TEMP_FILE
    else
        cat >> $INFO_TEMP_FILE
    fi
}

function resolve_filename {
    local suitfile="$1"

    case "$suitfile" in
        github:*)
            # automatic github URL
            echo $suitfile
            ;;

        http:*|https:*)
            # absolute url
            echo $suitfile
            ;;

        /*) # absolute path
            echo $suitfile
            ;;

        *)  # relative to the base
            echo "${BASE}${suitfile}"
            ;;
    esac
}

function resolve_public_github_url {
    local repo="$1"
    local path="$2"
    local rev="$3"

    echo "https://raw.githubusercontent.com/$repo/$rev/$path"
}

function resolve_private_github_url {
    local repo="$1"
    local path="$2"
    local rev="$3"

    echo "https://api.github.com/repos/$repo/contents/$path?ref=$rev"
}

function is_public_repo {
    local repo="$1"

    # without a token, you can't see private repos anyway
    [ -z "$GITHUB_TOKEN" ] && \
        return 0

    local filename=$( echo "$repo" | sed -e 's:/:.:' )
    local cache="$REPO_TEST_CACHE/$filename"
    debug "cache='$cache'"

    [ -f "$cache.public" ] && \
        return 0
    [ -f "$cache.private" ] && \
        return 1

    curl -sH "Authorization: token $GITHUB_TOKEN" \
        https://api.github.com/repos/$repo \
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
        github:*)
            local repo=$( echo "$1" | awk -F: '{ print $2 }' )
            local path=$( echo "$1" | awk -F: '{ print $3 }' )
            local rev=$( echo "$repo" | awk -F@ '{ print $2 }' )

            if [ -n "$rev" ]; then
                repo=$( echo "$repo" | awk -F@ '{ print $1 }' )
            else
                rev='master'
            fi

            if is_public_repo $repo; then
                url=$( resolve_public_github_url "$repo" "$path" "$rev" )
            else
                url=$( resolve_private_github_url "$repo" "$path" "$rev" )
                curlargs="-H 'Authorization: token $GITHUB_TOKEN' "
                curlargs="$curlargs -H 'Accept: application/vnd.github.v3.raw'"
            fi
            ;;

        *)  # use as-is
            ;;
    esac

    echo "$url"
    debug "curl --fail --progress-bar $curlargs $url > $CURL_TEMP_FILE"
    eval curl --fail --progress-bar $curlargs "$url" > $CURL_TEMP_FILE
}

function process_brewfile {
    local brewfile=$( resolve_filename "$1" )
    local tempfile

    case "$brewfile" in
        http:*|https:*|github:*)
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

function process_gemfile {
    local gemfile=$( resolve_filename "$1" )
    local tempfile

    case "$gemfile" in
        http:*|https:*|github:*)
            # fetch a remote file and process it locally
            if url=$( fetch_url "$gemfile" ); then
                action "process remote gemfile '$gemfile'"
                bundle install "--gemfile=$CURL_TEMP_FILE"
            else
                error "cannot process '$url': curl failure"
                return 1
            fi
            ;;

        *)  # process a local file
            if [ -f "$gemfile" ]; then
                action "process local gemfile '$gemfile'"
                bundle install "--gemfile=$gemfile"
            else
                error "cannot process '$gemfile': does not exist"
                return 1
            fi
            ;;
    esac
}

function clone_github_repo {
    local repo="$1"
    local destination="$2"

    if [ -z "$destination" ]; then
        destination="${REPO_DIR}/$repo"
    fi

    action "checkout '$repo' to $destination"

    if [ ! -d "$destination" ]; then
        mkdir -p "$destination"
        git clone git@github.com:${repo}.git "$destination"
        
        pushd "$destination" >/dev/null   # unnecessarily noisy

        [ -f Brewfile ] && \
            process_brewfile "${destination}/Brewfile"
        [ -f Gemfile ] && \
            process_gemfile "${destination}/Gemfile"
        [ -f script/bootstrap ] && \
            execute_shell_script "${destination}/script/bootstrap"

        popd >/dev/null   # unnecessarily noisy

    else
        status 'already exists, skipping'
    fi
}

function clone_repo {
    local source=$( echo "$1" | awk -F: '{ print $1 }' )
    local repo=$( echo "$1" | awk -F: '{ print $2 }' )
    local destination="$2"

    case $source in
        github)
            clone_github_repo "$repo" "$destination"
            ;;

        *)  error "suited only understands github repos"
            ;;
    esac
}

function execute_shell_script {
    local script=$( resolve_filename "$1" )

    case "$script" in
        http:*|https:*|github:*)
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
    elif [ "$filename" == 'gemfile' ]; then
        process_gemfile "$line"
    elif [[ "$filename" == *.sh ]]; then
        execute_shell_script "$line"
    else
        process_suitfile "$line"
    fi
}

function process_root_suitfile {
    local suitfile

    case "$1" in
        github:*)
            BASE=$( echo "$1" | awk -F: '{ print $1 ":" $2 ":" }' )
            suitfile=$( echo "$1" | awk -F: '{ print $3 }' )
            ;;

        -)  cat > $STDIN_TEMP_FILE
            BASE='./'
            suitfile=$STDIN_TEMP_FILE
            ;;

        *)  BASE=$(dirname "$1")"/"
            suitfile=$(basename "$1")
            ;;
    esac

    process_suitfile "$suitfile"
}

function process_suitfile {
    local suitfile=$( resolve_filename "$1" )
    local filename
    local line
    local tempfile
    local usefile

    case "$1" in
        http:*|https:*|/*|github:*)
            # process absolute path suitfiles as a new root suitfile
            # (absolute paths reset BASE)
            $BASH $SUITED_SH "$1"
            return
            ;;
        *)  # do nothing
            ;;
    esac

    case "$suitfile" in
        http:*|https:*|github:*)
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

            repo\ *)
                # clone a repo and initialise it
                local repo=$(
                    echo "$line" \
                        | awk '{ print $2 }'
                )
                local destination=$(
                    echo "$line" \
                        | awk '{ print $3 }' \
                        | sed -e "s:~:${HOME}:"
                )
                clone_repo $repo "$destination"
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
