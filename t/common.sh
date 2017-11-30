#!/bin/bash

TEST_DIR=$(dirname ${BASH_SOURCE[0]})
NR_FAILURE=0
STDERR=/dev/null

function canonicalize {
	local dir=$1
	shift
	[ -d "$dir" ] || mkdir -p "$dir" || die "unable to create directory '$dir'"
	cd "$dir"
	local ret="$(pwd)"
	cd - >/dev/null 2>&1
	echo "$ret"
}

SRC_DIR="$(canonicalize "$(dirname "${BASH_SOURCE[0]}")/../src")"

function test_init {
	NR_FAILURE=0
	export STASH_DIR="$(canonicalize "$(mktemp -d "$TEST_DIR/st.XXXXXX")")"
	export STASH_WORK_TREE="$(canonicalize "$(mktemp -d "$TEST_DIR/wt.XXXXXX")")"
	if [ -n "$DBG" ]; then
		LAUNCHER="bash -x"
		STDERR="dbg.log"
		rm "$STDERR"
	fi
}


function init_simple_stash {
	mkdir "$STASH_DIR/simple_stash"
	touch "$STASH_DIR/simple_stash/file1"
	mkdir "$STASH_DIR/simple_stash/dir1"
	touch "$STASH_DIR/simple_stash/dir1/file2"
}

function init_linked_stash {
	mkdir "$STASH_DIR/linked_stash"
	touch "$STASH_DIR/linked_stash/ll_file1"
	mkdir "$STASH_DIR/linked_stash/ll"
	touch "$STASH_DIR/linked_stash/ll/ll_file2"
	ln -s "$STASH_DIR/linked_stash/ll_file1" "$STASH_WORK_TREE/ll_file1"
	mkdir "$STASH_WORK_TREE/ll"
	ln -s "$STASH_DIR/linked_stash/ll/ll_file2" "$STASH_WORK_TREE/ll/ll_file2"
}

function init_missing_link {
	mkdir "$STASH_DIR/missing_link"
	touch "$STASH_DIR/missing_link/ml_file1"
	mkdir "$STASH_DIR/missing_link/ml"
	touch "$STASH_DIR/missing_link/ml/ml_file2"
	touch "$STASH_DIR/missing_link/ml/ml file3"
	ln -s "$STASH_DIR/missing_link/ml_file1" "$STASH_WORK_TREE/ml_file1"
	mkdir "$STASH_WORK_TREE/ml"
	ln -s "$STASH_DIR/missing_link/ml/ml_file2" "$STASH_WORK_TREE/ml/ml_file2"
}

function init_many_missing_link {
	mkdir "$STASH_DIR/many_missing_links"
	touch "$STASH_DIR/many_missing_links/mml_file1"
	mkdir "$STASH_DIR/many_missing_links/mml"
	touch "$STASH_DIR/many_missing_links/mml/mml_file2"
	touch "$STASH_DIR/many_missing_links/mml/mml file3"
	touch "$STASH_DIR/many_missing_links/mml/mml file4"
	touch "$STASH_DIR/many_missing_links/mml/mml file5"
	touch "$STASH_DIR/many_missing_links/mml/mml file6"
	ln -s "$STASH_DIR/many_missing_links/mml_file1" "$STASH_WORK_TREE/mml_file1"
	mkdir "$STASH_WORK_TREE/mml"
	ln -s "$STASH_DIR/many_missing_links/mml/mml_file2" "$STASH_WORK_TREE/mml/mml_file2"
}

function init_broken_link {
	mkdir "$STASH_DIR/broken link"
	touch "$STASH_DIR/broken link/bl_file1"
	mkdir "$STASH_DIR/broken link/bl"
	touch "$STASH_DIR/broken link/bl/bl_file2"
	touch "$STASH_DIR/broken link/bl/bl file3"
	ln -s "$STASH_DIR/broken link/bl_file1" "$STASH_WORK_TREE/bl_file1"
	mkdir "$STASH_WORK_TREE/bl"
	ln -s "$STASH_DIR/broken link/bl/bl_file2" "$STASH_WORK_TREE/bl/bl_file2"
	ln -s "$STASH_DIR/broken link/bl/bl file3" "$STASH_WORK_TREE/bl/bl file3"
	ln -s "$STASH_DIR/broken link/bl/bl file4" "$STASH_WORK_TREE/bl/bl file4"
}

function init_2_broken_links {
	mkdir "$STASH_DIR/2 broken links"
	touch "$STASH_DIR/2 broken links/2bl_file1"
	mkdir "$STASH_DIR/2 broken links/2bl"
	touch "$STASH_DIR/2 broken links/2bl/2bl_file2"
	touch "$STASH_DIR/2 broken links/2bl/2bl file3"
	ln -s "$STASH_DIR/2 broken links/2bl_file1" "$STASH_WORK_TREE/2bl_file1"
	mkdir "$STASH_WORK_TREE/2bl"
	ln -s "$STASH_DIR/2 broken links/2bl/2bl_file2" "$STASH_WORK_TREE/2bl/2bl_file2"
	ln -s "$STASH_DIR/2 broken links/2bl/2bl file3" "$STASH_WORK_TREE/2bl/2bl file3"
	ln -s "$STASH_DIR/2 broken links/2bl/2bl file4" "$STASH_WORK_TREE/2bl/2bl file4"
	ln -s "$STASH_DIR/2 broken links/2bl/2bl file5" "$STASH_WORK_TREE/2bl/2bl file5"
}

function init_stash_with_space {
	mkdir "$STASH_DIR/stash with space"
	touch "$STASH_DIR/stash with space"
	touch "$STASH_DIR/stash with space/file_in_stash_with_space"
}

function init_stash_with_file_with_space {
	mkdir "$STASH_DIR/stash_with_file_with_space"
	touch "$STASH_DIR/stash_with_file_with_space/file with space"
}

function init_stash_with_dir_with_space {
	mkdir "$STASH_DIR/stash_with_dir_with_space"
	mkdir "$STASH_DIR/stash_with_dir_with_space/dir with space"
	touch "$STASH_DIR/stash_with_dir_with_space/dir with space/file"
}

function fail {
	NR_FAILURE=$(($NR_FAILURE + 1))
	echo "$@" >&2
}

function ok {
	$LAUNCHER "$SRC_DIR/stash.sh" "$@" >/dev/null 2>>$STDERR
	local failed=$?
	[ $failed -ne 0 ] && fail "Failed case: stash" "$@"
}

function not_ok {
	$LAUNCHER "$SRC_DIR/stash.sh" "$@" >/dev/null 2>>$STDERR
	local failed=$?
	[ $failed -eq 0 ] && fail "Failed case: stash" "$@"
}

function match {
	local match_regex="$1"
	shift
	$LAUNCHER "$SRC_DIR/stash.sh" "$@" 2>>$STDERR | grep -E -q "$match_regex"
	local failed=$?
	[ $failed -eq 0 ] || fail "Failed case: stash" "$@" "(failed match: '$match_regex')"
}

function match2 {
	local match_regex=$1
	shift
	$LAUNCHER "$SRC_DIR/stash.sh" "$@" 2>&1 >/dev/null | grep -E -q "$match_regex"
	local failed=$?
	[ $failed -eq 0 ] || fail "Failed case: stash" "$@" "(failed match on stderr: '$match_regex')"
}

function is_str {
	[ "$1" = "$2" ] || fail "Failed case: $1 = $2"
}

function test_cleanup {
	rm -r "$STASH_DIR"
	rm -r "$STASH_WORK_TREE"
	exit $NR_FAILURE
}


