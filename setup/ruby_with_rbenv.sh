if ! type -t rbenv >/dev/null; then
    status 'Install rbenv'
    brew install rbenv
    eval "$(rbenv init - )"

    add_to_bash_profile <<'EOF'

# setup rbenv
eval "$(rbenv init - )"
EOF
    inform "'rbenv init' added to .bash_profile"

    local latest=$(
        rbenv install --list \
            | grep -v - \
            | tail -1 \
            | sed -e 's/ //g'
    )
    status "Install ruby ${latest}"
    rbenv install -s ${latest}
    rbenv global ${latest}
    rbenv rehash

    status 'Install bundler'
    gem install bundler
else
    # ensure rbenv init has occurred (open a shell, run suited such that
    # rbenv is installed, then run it again and anything rubyish will fail
    # as bash_profile startup is not run)
    eval "$(rbenv init -)"
fi
