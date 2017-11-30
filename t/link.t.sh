#!/bin/bash

cur_dir="$(dirname "${BASH_SOURCE[0]}")"

. "${cur_dir}/common.sh"

test_init

init_simple_stash
ok link simple_stash 

init_stash_with_space
ok link "stash with space" 

init_stash_with_file_with_space
ok link stash_with_file_with_space

init_stash_with_dir_with_space
ok link stash_with_dir_with_space

test_cleanup
