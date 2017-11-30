#!/bin/bash

cur_dir="$(dirname "${BASH_SOURCE[0]}")"

. "${cur_dir}/common.sh"

test_init

init_linked_stash
ok rm linked_stash
find "$STASH_WORK_TREE" -type l -exec readlink {} \;
nr_links=$(find "$STASH_WORK_TREE" -type l -exec readlink {} \; | grep 'linked_stash' | wc -l)
[ $nr_links -eq 0 ] || fail "stash unlink linked_stash"
[ ! -e "$STASH_DIR/linked_stash" ] || fail "stash rm linked_stash (dir still exists)"

init_2_broken_links
ok rm "2 broken links"
nr_links=$(find "$STASH_WORK_TREE" -type l -exec readlink {} \; | grep '2_broken_links' | wc -l)
[ $nr_links -eq 0 ] || fail "stash rm 2 broken links"
[ ! -e "$STASH_DIR/2 broken links" ] || fail "stash rm 2 broken links (dir still exists)"

test_cleanup
