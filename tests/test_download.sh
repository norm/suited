#!/usr/bin/env bats

OLD_UMASK=$(umask)

@test "test download from http" {
    [ ! -f "$HOME/bumph.txt" ]
    bash suited.sh tests/download_http.suitfile
    [ -f "$HOME/bumph.txt" ]
    diff -u $HOME/bumph.txt tests/output_download_http.txt
}

@test "test download from github" {
    [ ! -f "$HOME/readme.txt" ]
    bash suited.sh tests/download_github.suitfile
    [ -f "$HOME/readme.txt" ]
    diff -u $HOME/readme.txt tests/output_download_github.txt
}
