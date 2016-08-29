local devdir
local package
local trigger=/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

devdir=$( xcode-select -print-path 2>/dev/null || true )
[ -z "$devdir" ] \
    || ! [ -f "$devdir/usr/bin/git" ] \
    || ! [ -f /usr/include/iconv.h ] && {

        status 'downloading Xcode Command Line Tools'

        # forces softwareupdate to list the cli tools
        sudo touch $trigger
        package=$(
            softwareupdate -l \
                | egrep '\* Command Line (Dev|Tools)' \
                | sed -e 's/^[ *]*//'
        )
        sudo softwareupdate -i "$package"
        sudo rm -f $trigger

        if ! [ -f /usr/include/iconv.h ]; then
            # user install of tools
            xcode-select --install
        fi
}

accept_xcode_license
