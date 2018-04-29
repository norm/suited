#!/bin/bash
#
# FIXME introduction and documentation URL

# stop immediately on errors
set -e

VERSION='0.9'
SUITED_SH="$0"
REPO_TEST_CACHE=$( mktemp -d '/tmp/suited.repotest.XXXXX' )
CURL_TEMP_FILE=$( mktemp '/tmp/suited.curl.XXXXX' )
CRONTAB_TEMP_FILE=$( mktemp '/tmp/suited.cron.XXXXX' )
STDIN_TEMP_FILE=$( mktemp 'suited.stdin.XXXXX' )
INFO_TEMP_FILE=$( mktemp '/tmp/suited.info.XXXXX' )
DEBUG=0
SUDO=1
BASE=
trap cleanup EXIT

# where to clone repos to? (defaults to "~/Code/user/repo")
REPO_DIR="${REPO_DIR:=${HOME}/Code}"

# where is homebrew installed?
HOMEBREW_PREFIX="${HOMEBREW_PREFIX:=/usr/local}"
HOMEBREW_REPOSITORY="${HOMEBREW_REPOSITORY:=/usr/local/Homebrew}"

# hostname?
HOST="${HOST:=$(hostname -s)}"

# ANSI sequences
bold="\e[1m"
cyan="\e[36m"
yellow="\e[33m"
blue="\e[34m"
green="\e[32m"
magenta="\e[35m"
reset="\e[0m"

function action {
    printf "${yellow}=== ${1}${reset}\n" >&2
}

function status {
    printf "${blue}--- ${1}${reset}\n" >&2
}

function error {
    printf "${bold}${magenta}*** ${1}${reset}\n" >&2
}

function success {
    printf "${green}${1}${reset}\n" >&2
}

function abort {
    error "$1"
    exit 1
}

function debug_output {
    printf "${cyan}    ${*}${reset}\n" >&2
}

function debug {
    [ $DEBUG -eq 1 ] \
        && debug_output "$*" \
        || true
}

function deprecated {
    local version="$1"
    local text="$2"

    status "Deprecation warning: ${text}"
    status "This will be removed by version ${version}."
}

function usage {
    cat << EOF | sed -e 's/^        //'
        Usage:

        suited [-d] [-n] [-u] [-v] {suitfile | -} [suitfile...]

            -d  turn on debugging
            -n  turn off sudo attempt
            -u  update suited
            -v  show suited version

        A suitfile of '-' means to use STDIN (eg. \`echo "..." | suited -\`).
        Multiple suitfiles can be specified.

        Suitfiles are documented on GitHub:
        https://github.com/norm/suited/blob/master/documentation/suitfile.markdown
EOF

    ERRORS=silent
    exit 0
}

function fetch_current_suited {
    curl \
        --fail --silent \
        https://raw.githubusercontent.com/norm/suited/master/suited.sh \
            > $CURL_TEMP_FILE

    [ $? != 0 ] \
        && abort "Couldn't fetch the current version of suited from GitHub"

    now=$(
        grep VERSION= $CURL_TEMP_FILE \
            | head -1 \
            | sed -e 's/VERSION=//' -e "s/'//g"
    )

    local this_major=$( echo $VERSION | awk -F. '{ print $1 }' )
    local that_major=$( echo $now | awk -F. '{ print $1 }' )
    if [ $that_major -gt $this_major ]; then
        echo $now
        return
    fi

    local this_minor=$( echo $VERSION | awk -F. '{ print $2 }' )
    local that_minor=$( echo $now | awk -F. '{ print $2 }' )
    if [ $that_minor -gt $this_minor ]; then
        echo $now
        return
    fi

    local this_patch=$( echo $VERSION | awk -F. '{ print $3 }' )
    local that_patch=$( echo $now | awk -F. '{ print $3 }' )
    if [ $that_patch -gt $this_patch ]; then
        echo $now
        return
    fi
}

function report_version {
    echo "This is suited version: $VERSION"

    local now=$( fetch_current_suited )
    if [ -n "$now" ]; then
        printf "\n${magenta}${bold}"
        echo "A more recent version $now is available."
        echo "Run \`suited -u\` to upgrade."
        printf "${reset}\n"
    fi

    ERRORS=silent
    exit 0
}

function update_version {
    local now=$( fetch_current_suited )

    if [ -n "$now" ]; then
        echo "Upgrading from $VERSION to $now..."
        cp $CURL_TEMP_FILE $SUITED_SH
        chmod 755 $SUITED_SH
    else
        echo "You have the latest published version of suited."
    fi

    ERRORS=silent
    exit
}

function silent_pushd {
    # pushd reports the stack, this output is not wanted
    pushd "$1" >/dev/null
}

function silent_popd {
    # popd reports the stack, this output is not wanted
    popd >/dev/null
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
        echo ''
    fi

    if [ "$ERRORS" == 'probably' ]; then
        echo ''
        error 'Something went wrong!'
        error 'Re-running suited may fix things (if it was a temporary error).'
    fi

    # return back up the stack of directories
    # (this means removing the STDIN_TEMP_FILE is more likely to work)
    while popd >/dev/null 2>&1; do :; done

    rm -rf $REPO_TEST_CACHE $CRONTAB_TEMP_FILE $CURL_TEMP_FILE $INFO_TEMP_FILE $STDIN_TEMP_FILE
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
    if [ -n "$*" ]; then
        echo "$*" >> $INFO_TEMP_FILE
    else
        echo '' >> $INFO_TEMP_FILE
        cat >> $INFO_TEMP_FILE
    fi
}

function resolve_filename {
    local filename="$1"

    case "$filename" in
        github:*)
            # automatic github URL
            echo $filename
            ;;

        http:*|https:*)
            # absolute url
            echo $filename
            ;;

        /*) # absolute path
            echo $filename
            ;;

        *)  # relative to the base
            echo "${BASE}${filename}"
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

function check_url {
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

    debug "curl --fail --head $curlargs $url"
    eval curl --fail --head $curlargs "$url" >/dev/null 2>/dev/null
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

function update_git_clone {
    local destination="$1"

    silent_pushd "$destination"

    if [ -z "$SUITED_DONT_PULL_REPOS" ]; then
        git fetch

        # report the short state, but only if there are changes
        git status -sb | grep -v '^## master...origin/master$' \
            || true

        # only pull if there are no new local commits
        if git status -sb | grep '## master...origin/master .behind'; then
            # pull may still fail ("changes ... would be overwritten")
            # but this is not an error worth stopping suited for
            git pull \
                || error "Could not pull latest changes to $repo"
        fi
    fi

    silent_popd
}

function add_to_crontab {
    local crontab="$1"
    local attempt="${2:-no}"
    local email
    local search_for
    local usefile

    case "$crontab" in
        http:*|https:*|github:*)
            # fetch a remote file and process it locally
            action "process remote crontab '$crontab'"
            if url=$( fetch_url "$crontab" ); then
                usefile="$CURL_TEMP_FILE"
            else
                if [ $attempt == 'no' ]; then
                    error "cannot process '$url': curl failure"
                    return 1
                else
                    debug "$crontab does not exist"
                    return 0
                fi
            fi
            ;;

        *)  # process a local file
            action "process local crontab '$crontab'"
            if [ -f "$crontab" ]; then
                usefile="$crontab"
            else
                error "cannot process '$crontab': does not exist"
                return 1
            fi
            ;;
    esac

    if ! crontab -l > $CRONTAB_TEMP_FILE 2>/dev/null; then
        email=$( git config user.email )
        [ -z "$email" ] \
            && email='crontab@mailinator.com'

        cat << EOF | sed -e 's/^ *//' > $CRONTAB_TEMP_FILE
            MAILTO=$email
            PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin

            #mn   hr    dom   mon   dow   cmd
EOF

        status 'initialising crontab'
        inform <<EOF
Created a new crontab file for you. Output and errors from cron jobs will be
delivered to "${email}".
You can change this with "crontab -e" if necessary.
EOF
    fi

    for line in $( cat "$usefile" ); do
        search_for=$(
            echo "$line" \
                | sed -e 's/\*/\\*/g' -e 's/  */ */g'
        )

        if ! grep -q "$search_for" $CRONTAB_TEMP_FILE; then
            echo "$line" >> $CRONTAB_TEMP_FILE
            inform <<EOF
Added to your crontab:
    $line
EOF
        fi
    done

    crontab $CRONTAB_TEMP_FILE
}

function process_dockfile_line {
    local command="$1"
    local app="$2"
    local rel="$3"
    local rel_app="$4"
    local replacing="$5"

    case "$command" in
        add)
            status "Adding $2"
            if [ -z "$replacing" ]; then
                replacing="$app"
            fi

            case "$app" in
                /*) ;;
                *)  app="/Applications/$app.app"
                    ;;
            esac

            if [ -n "$rel" ]; then
                dockutil \
                    --add "$app" \
                    --$rel "$rel_app" \
                    --replacing $replacing \
                    --no-restart \
                        || true
            else
                dockutil \
                    --add "$app" \
                    --replacing $replacing \
                    --no-restart \
                        || true
            fi
            ;;

        remove)
            status "Removing $app"
            dockutil --remove "$app" --no-restart \
                >/dev/null  # not being in the dock is not an error
            ;;

        ''|\#*)
            # comment or blank line, ignore
            ;;

        *)  status "Unknown action $command: $@"
            ;;
    esac
}

function process_dockfile {
    local dockfile=$( resolve_filename "$1" )

    type -t dockutil >/dev/null \
        || brew install dockutil

    case "$dockfile" in
        http:*|https:*|github:*)
            # fetch a remote file and process it locally
            action "process remote dockfile '$dockfile'"
            if url=$( fetch_url "$dockfile" ); then
                usefile="$CURL_TEMP_FILE"
            else
                error "cannot process '$url': curl failure"
                return 1
            fi
            ;;

        *)  # process a local file
            action "process local dockfile '$dockfile'"
            if [ -f "$dockfile" ]; then
                usefile="$dockfile"
            else
                error "cannot process '$dockfile': does not exist"
                return 1
            fi
            ;;
    esac

    for line in $( cat "$usefile" ); do
        eval process_dockfile_line $line
    done

    killall Dock
}

function process_brewfile {
    local brewfile=$( resolve_filename "$1" )
    local attempt="${2:-no}"

    case "$brewfile" in
        http:*|https:*|github:*)
            # fetch a remote file and process it locally
            action "process remote brewfile '$brewfile'"
            if url=$( fetch_url "$brewfile" ); then
                brew bundle "--file=$CURL_TEMP_FILE"
            else
                if [ $attempt == 'no' ]; then
                    error "cannot process '$url': curl failure"
                    return 1
                else
                    debug "no brewfile ${brewfile}"
                fi
            fi
            ;;

        *)  # process a local file
            action "process local brewfile '$brewfile'"
            if [ -f "$brewfile" ]; then
                brew bundle "--file=$brewfile"
            else
                error "cannot process '$brewfile': does not exist"
                return 1
            fi
            ;;
    esac
    echo ''
}

function install_ruby_version {
    rbenv install -s
    rbenv rehash
    gem list -I bundler \
        && gem install bundler \
        || true
}

function process_gemfile {
    local gemfile=$( resolve_filename "$1" )

    case "$gemfile" in
        http:*|https:*|github:*)
            # fetch a remote file and process it locally
            action "process remote gemfile '$gemfile'"
            if url=$( fetch_url "$gemfile" ); then
                bundle install "--gemfile=$CURL_TEMP_FILE"
            else
                error "cannot process '$url': curl failure"
                return 1
            fi
            ;;

        *)  # process a local file
            action "process local gemfile '$gemfile'"
            if [ -f "$gemfile" ]; then
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
    else
        update_git_clone "$destination"
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

function download_file {
    local source="$1"
    local destination="$2"

    if url=$( fetch_url "$source" ); then
        cp "$CURL_TEMP_FILE" "$destination"
    else
        debug "$source does not exist"
        return 1
    fi
}

function setup_from_directory {
    directory="$1"

    case "$directory" in
        http:*|https:*|github:*)
            if check_url "${directory}suitfile"; then
                process_suitfile "${directory}suitfile"
            else
                deprecated 1.0 "Use of dir/ without a suitfile"

                process_brewfile "${directory}Brewfile" try
                execute_shell_script "${directory}bootstrap" try
                add_to_crontab "${directory}crontab" try
            fi
            ;;

        *)  # local directory
            silent_pushd "$directory"
            if [ -f suitfile ]; then
                process_suitfile "${directory}/suitfile"
            else
                # install any homebrew dependencies
                deprecated 1.0 "Use of dir/ without a suitfile"

                if [ -f Brewfile ]; then
                    process_brewfile "${directory}/Brewfile"
                fi

                if [ -f script/bootstrap ]; then
                    # run the bootstrap script, if there is one...
                    execute_shell_script "${directory}/script/bootstrap"
                elif [ -f bootstrap ]; then
                    execute_shell_script "${directory}/bootstrap"
                else
                    # ...otherwise initialise things that look initialisable
                    [ -f .ruby-version ] && \
                        install_ruby_version
                    [ -f Gemfile ] && \
                        process_gemfile "${directory}/Gemfile"
                fi

                # lines to add to the crontab
                if [ -f crontab ]; then
                    add_to_crontab "${directory}/crontab"
                fi
            fi
            silent_popd
            ;;
    esac
}

function execute_shell_script {
    local script=$( resolve_filename "$1" )
    local attempt="${2:-no}"
    local url

    case "$script" in
        http:*|https:*|github:*)
            # fetch a remote file and process it locally
            action "execute remote script '$script'"
            if url=$( fetch_url "$script" ); then
                source "$CURL_TEMP_FILE"
            else
                if [ $attempt == 'no' ]; then
                    error "cannot execute '$url': curl failure"
                    return 1
                else
                    debug "$script does not exist"
                    return 1
                fi
            fi
            ;;

        *)  # process a local file
            action "execute local script '$script'"
            if [ -f "$script" ]; then
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
    elif [ "$filename" == 'crontab' ]; then
        add_to_crontab "$line"
    elif [ "$filename" == 'dockfile' ]; then
        process_dockfile $( resolve_filename "$line" )
    elif [ "$filename" == 'gemfile' ]; then
        process_gemfile "$line"
    elif [[ "$filename" == *.sh ]]; then
        execute_shell_script "$line"
    elif [[ "$line" == */ ]]; then
        setup_from_directory $( resolve_filename "$line" )
    else
        process_suitfile "$line"
    fi
}

function process_suitfile {
    local suitfile=$( resolve_filename "$1" )
    local oldbase="$BASE"
    local filename
    local line
    local usefile

    # a new suitfile means a new BASE for locating relative filenames
    case "$suitfile" in
        http:*|https:*)
            BASE="$(dirname "$suitfile")/"
            # nothing?
            ;;

        github:*)
            repo="$( echo "$1" | awk -F: '{ print $1 ":" $2 ":" }' )"
            path="$(dirname "$(echo "$1" | awk -F: '{ print $3 }')")/"
            BASE="${repo}${path}"
            ;;

        -)  cat > $STDIN_TEMP_FILE
            BASE='./'
            suitfile=$STDIN_TEMP_FILE
            ;;

        *)  BASE=$(dirname "$1")"/"
            [ "$path" = './' ] && \
                path=''
            suitfile=$(basename "$1")
            ;;
    esac

    case "$suitfile" in
        http:*|https:*|github:*)
            # fetch a remote file and process it locally
            action "process remote suitfile '$suitfile'"
            if url=$( fetch_url "$suitfile" ); then
                usefile=$CURL_TEMP_FILE
            else
                error "cannot process '$url': curl failure"
                return 1
            fi
            ;;

        *)  # process a local file
            action "process local suitfile '${BASE}${suitfile}'"
            if [ -f "${BASE}${suitfile}" ]; then
                usefile="${BASE}${suitfile}"
            else
                error "cannot process '${BASE}${suitfile}': does not exist"
                return 1
            fi
            ;;
    esac

    IFS=$'\n'
    for line in $( cat "$usefile" ); do
        # trim whitespace
        line=$( echo "$line" | sed -e 's/^ *//' -e 's/ *$//' )

        debug "$line"
        case "$line" in
            \#*)
                # commented line, ignore
                ;;

            inform\ *)
                inform "$(echo "$line" | sed -e 's/^inform *//')"
                ;;

            echo*)
                echo "$(echo "$line" | sed -e 's/^echo *//')"
                ;;

            action\ *)
                action "$(echo "$line" | sed -e 's/^action *//')"
                ;;

            status\ *)
                status "$(echo "$line" | sed -e 's/^status *//')"
                ;;

            error\ *)
                error "$(echo "$line" | sed -e 's/^error *//')"
                ;;

            abort\ *)
                abort "$(echo "$line" | sed -e 's/^abort *//')"
                ;;

            debug\ *)
                debug_output "$(echo "$line" | sed -e 's/^debug *//')"
                ;;

            success\ *)
                success "$(echo "$line" | sed -e 's/^success *//')"
                ;;

            repo\ *)
                # clone a repo and initialise it
                local repo=$(
                    echo "$line" \
                        | awk '{ print $2 }'
                )
                local destination=$(
                    echo "$line" \
                        | tr -s ' ' | cut -d ' ' -f3- \
                        | sed -e "s:~:${HOME}:"
                )
                clone_repo $repo "$destination"
                setup_from_directory "$destination"
                ;;

            clone\ *)
                # clone a repo (without any initialising)
                local repo=$(
                    echo "$line" \
                        | awk '{ print $2 }'
                )
                local destination=$(
                    echo "$line" \
                        | tr -s ' ' | cut -d ' ' -f3- \
                        | sed -e "s:~:${HOME}:"
                )
                clone_repo $repo "$destination"
                ;;

            download\ *)
                debug "downloading file"
                # copy a remote file to the local filesystem
                local file=$(
                    echo "$line" \
                        | awk '{ print $2 }'
                )
                local destination=$(
                    echo "$line" \
                        | tr -s ' ' | cut -d ' ' -f3- \
                        | sed -e "s:~:${HOME}:"
                )
                download_file $file "$destination"
                ;;

            loginitem\ *)
                debug "adding loginitem"
                local application=$(
                    echo "$line" \
                        | cut -c10- \
                        | sed -e 's/^ *//'
                )
                osascript -e "
                    tell application \"System Events\"
                        make login item at end with properties { \
                            path: \"/Applications/${application}.app\", \
                            name: \"$application\", \
                            hidden: false \
                        }
                    end tell
                "
                ;;

            *)  process_line "$line"
                ;;
        esac
    done

    # restore the old BASE setting (pop the stack)
    BASE="$oldbase"

    return 0
}

while getopts "dhnuvx" option; do
    case $option in
        d)  DEBUG=1;;
        n)  SUDO=0;;
        u)  update_version; exit;;
        v)  report_version;;
        x)  set -x;;
        ?|h) 
            usage;;
    esac
done
shift $(( OPTIND - 1 ))

ERRORS=probably

# no suitfile is an error
[ "$#" == 0 ] \
    && abort "No suitfile(s) specified"

# no GITHUB_TOKEN means no access to private content
# (this is not an error if you're not trying to fetch any, of course)
[ -z "$GITHUB_TOKEN" ] && {
    status "GITHUB_TOKEN is not set, so private GitHub repos will be inaccessible"
    sleep 2
}

# first, check we can sudo
[ "$SUDO" == 1 ] && {
    action "Checking you can sudo, enter password if prompted..."
    sudo -v || {
        echo ''
        error "suited.sh needs sudo access to configure Xcode"
        exit 1
    }
}

[ ! -d $HOME/.ssh ] && \
    install -m 0700 -d $HOME/.ssh
[ ! -f $HOME/.ssh/known_hosts ] && \
    ssh-keyscan -t rsa github.com >$HOME/.ssh/known_hosts 2>/dev/null

for file in "$@"; do
    process_suitfile "$file"
done

ERRORS=
