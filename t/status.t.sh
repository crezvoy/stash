#!/bin/bash

cur_dir="$(dirname "${BASH_SOURCE[0]}")"

. "${cur_dir}/common.sh"

test_init

init_simple_stash
match 'simple_stash: not linked$' status
init_linked_stash
match 'linked_stash: linked$' status
init_missing_link
match 'missing_link: linked, 1 missing link\(s\)' status
init_many_missing_link
match 'many_missing_links: linked, 4 missing link\(s\)' status
init_broken_link
match 'broken link: linked, 1 broken link\(s\)' status
init_2_broken_links
match '2 broken links: linked, 2 broken link\(s\)' status

test_cleanup
