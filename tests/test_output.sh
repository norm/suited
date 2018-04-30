#!/usr/bin/env bats

@test "test output example" {
    run bash suited.sh output-example.suitfile
    diff -u <(echo "$output") tests/output.txt
}
