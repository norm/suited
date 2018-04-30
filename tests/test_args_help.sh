#!/usr/bin/env bats

@test "test -h argument" {
    run bash suited.sh -h
    diff <(echo "$output") tests/output_args_help.txt
}
