#!/usr/bin/env bats

@test "test needenv aborts without env var" {
    run bash suited.sh tests/needenv.suitfile
    [ "$status" = 1 ]
    [[ "$output" = *"environment variable BANANA needs to be set"* ]]
}

@test "test needenv continues with env var" {
    export BANANA=banana
    run bash suited.sh tests/needenv.suitfile
    [ "$status" = 0 ]
    [[ "$output" = *"BANANA is set"* ]]
}

# @test "test symlink replaces existing symlinks" {
#     rm -f $HOME/snarf.txt
#     ln -s /dev/null $HOME/snarf.txt
#     bash suited.sh tests/symlink.suitfile
#     [ -L $HOME/snarf.txt ]
#     run readlink $HOME/snarf.txt
#     [ "$output" == "$HOME/bob.txt" ]
# }

# @test "test symlink does not replace files" {
#     rm -f $HOME/snarf.txt
#     touch $HOME/snarf.txt
#     run bash suited.sh tests/symlink.suitfile
#     [[ "$output" = *"cannot make symlink"*"already exists"* ]]
# }
