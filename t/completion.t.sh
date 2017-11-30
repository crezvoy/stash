#!/bin/bash

SRC_DIR="$(dirname "${BASH_SOURCE[0]}")/.."
stash() {
	$SRC_DIR/stash.sh "$@"
}

source /usr/share/bash-completion/bash_completion
source "$SRC_DIR/src/bash_completion"
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

test_init

comp_test() {
	COMP_LINE="$1"
	COMP_CWORD="$2"
	local match="$3"
	COMP_WORDS=()
	COMPREPLY=()
	IFS=' ' read -r -a COMP_WORDS <<< "$COMP_LINE"	
	while [ $COMP_CWORD -gt ${#COMP_WORDS[@]} ]; do
		COMP_WORDS+=(' ')
	done
	COMP_POINT=${#COMP_LINE}
	
	_xfunc stash _stash

	local compreply_str="${COMPREPLY[*]}"

	is_str "$compreply_str" "$match"
}

comp_test "stash " 1 "-h --help -v --version --stash --work-tree link unlink status rm cd version help"
comp_test "stash -" 1 "-h --help -v --version --stash --work-tree"
comp_test "stash l" 1 "link"
comp_test "stash u" 1 "unlink"
comp_test "stash st" 1 "status"
comp_test "stash r" 1 "rm"
comp_test "stash c" 1 "cd"

init_simple_stash
init_linked_stash
init_broken_link
init_missing_link

comp_test "stash link  " 2 "simple_stash missing_link"
comp_test "stash unlink  " 2 "missing_link broken link linked_stash"
comp_test "stash rm  " 2 "simple_stash missing_link broken link linked_stash"
export tmp="$(canonicalize "$(mktemp -d "$TEST_DIR/st.XXXXXX")")"
mkdir "$tmp/dir1"
mkdir "$tmp/dir2"
comp_test "stash --stash $tmp/" 2 "$tmp/dir1 $tmp/dir2"
rm -r "$tmp"

test_cleanup
