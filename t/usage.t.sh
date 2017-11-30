#!/bin/bash

cur_dir="$(dirname "${BASH_SOURCE[0]}")"

. "${cur_dir}/common.sh"

test_init
ok help
ok -h
ok --help
match2 'unknown argument' ---help
match 'stash.sh [0-9]\.[0-9]\.([0-9])?' version 
match 'stash.sh [0-9]\.[0-9]\.([0-9])?' -v
match 'stash.sh [0-9]\.[0-9]\.([0-9])?' --version
test_cleanup
