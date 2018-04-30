#!/usr/bin/env bats

@test "test symlink creates symlinks" {
    touch $HOME/bob.txt
    [ ! -e $HOME/snarf.txt ]
    bash suited.sh tests/symlink.suitfile
    [ -L $HOME/snarf.txt ]
}

@test "test symlink replaces existing symlinks" {
    rm -f $HOME/snarf.txt
    ln -s /dev/null $HOME/snarf.txt
    bash suited.sh tests/symlink.suitfile
    [ -L $HOME/snarf.txt ]
    run readlink $HOME/snarf.txt
    [ "$output" == "$HOME/bob.txt" ]
}

@test "test symlink does not replace files" {
    rm -f $HOME/snarf.txt
    touch $HOME/snarf.txt
    run bash suited.sh tests/symlink.suitfile
    [[ "$output" = *"cannot make symlink"*"already exists"* ]]
}
