#!/bin/bash

STASH="${STASH_DIR:-$HOME/.local/stash/stash}"
WORK_TREE="${STASH_WORK_TREE:-$HOME}"
APP_NAME="$(basename $0)"


###########
# Helpers #
###########

die() {
	echo "$1" >&2
	exit 1
}

canonicalize() {
	local dir=$1
	shift
	[ -d "$dir" ] || mkdir -p "$dir" || die "unable to create directory '$dir'"
	cd "$dir"
	local ret="$(pwd)"
	cd - >/dev/null 2>&1
	echo "$ret"
}

canonicalize_stash() {
	canonicalize "$STASH"
}

canonicalize_work_tree() {
	canonicalize "$WORK_TREE"
}


check_prereq() {
	which readlink >/dev/null 2>&1 || die "missing readlink utility"
	which find >/dev/null 2>&1 || die "missing find utility"
	which grep >/dev/null 2>&1 || die "missing grep utility"
}


################
# link command #
################

stash_link_usage() {
	cat <<- EOF
	$APP_NAME link stash_name
	    link a stash into the work_tree
	EOF
}

stash_link_sub() {
	local action="$1"
	local stash_name="$2"
	local work_tree="$(canonicalize_work_tree)"
	local stash="$(canonicalize_stash)"

	local stash_dir="$stash/$stash_name"
	[ -d "$stash_dir" ] || die "$stash is not a known stash"
	while read dir; do
		local rel="${dir/$stash_dir\//}"
		local work_tree_dir="$work_tree/$rel"
		if [ "x$action" = "xcheck" ]; then
			[ ! -e "$work_tree_dir" -o -d "$work_tree_dir" ] || die "refusing to overwrite $work_tree_dir"
		elif [ "x$action" = "xlink" ]; then 
			mkdir -p "$work_tree_dir"	
		fi
	done < <(find "$stash_dir" -mindepth 1 -type d)
	while read stash_file; do
		local rel_file="${stash_file/$stash_dir\//}"
		local wt_file="$work_tree/$rel_file" 
		if [ "x$action" = "xcheck" ]; then
			[ ! -e "$wt_file" ] || die "refusing to overwrite $wt_file"
		elif [ "x$action" = "xlink" ]; then 
			ln -s "$stash_file" "$wt_file"
		fi

	done < <(find "$stash_dir" -type f,l)
}


stash_link() {
	[ $# -eq 1 ] || die "$(stash_link_usage)"
	stash_link_sub check "$1"
	stash_link_sub link "$1"
}

##################
# unlink command #
##################

stash_unlink_usage() {
	cat <<- EOF
	$APP_NAME unlink stash_name
	    link a stash from the work_tree
	EOF
}

stash_unlink() {
	[ $# -eq 1 ] || die "$(stash_unlink_usage)"
	local stash_name="$1"
	local work_tree="$(canonicalize_work_tree)"
	local stash="$(canonicalize_stash)"
	local stash_dir="$stash/$stash_name"
	while read lnk; do
		local link_target="$(readlink "$lnk")"
		[[ "$link_target" == "$stash_dir"* ]] && rm "$lnk"
	done < <(find "$work_tree" -type l)
}


##################
# status command #
##################

stash_status_usage() {
	cat <<- EOF
	$APP_NAME status [stash_name]
	    list stashs and their link status, or query the status of a given
	    stash
	EOF
}

stash_status_single() {
	local stash_dir="$1"; shift
	local work_tree="$1"; shift
	local stash_name="$(basename "$stash_dir")"
	[ -d "$stash_dir" ] || die "$stash_name is not a stash"

	local nr_links=$(find "$work_tree" -type l -exec readlink "{}" \; | grep "^$stash_dir" | wc -l)
	local nr_files=0
	local nr_missing=0
	while read stash_file; do
		nr_files=$((nr_files + 1))
		local rel_path="${stash_file##$stash_dir/}"
		local link_path="$work_tree/$rel_path"
		if [ ! -h "$link_path" ]; then
			nr_missing=$((nr_missing + 1))
			continue
		fi
		if [[ ! "$(readlink "$link_path")" =~ "$stash_dir" ]]; then
			nr_missing=$((nr_missing + 1))
		fi
	done < <(find "$stash_dir" -type f,l)
	local nr_broken=$(($nr_links - $nr_files - $nr_missing))

	echo -n "$stash_name"
	if [ $nr_links -eq 0 ]; then
		echo -n ": not linked"
	else
		echo -n ": linked"
	fi

	if [ $nr_links -gt 0 -a $nr_missing -gt 0 ]; then
		echo -n ", $nr_missing missing link(s)"
	fi
	if [ $nr_broken -gt 0 ]; then
		echo -n ", $nr_broken broken link(s)"
	fi
	echo ""	
}

stash_status() {
	[ $# -le 1 ] || die "$(stash_status_usage)"
	local work_tree="$(canonicalize_work_tree)"
	local stash="$(canonicalize_stash)"
	if [ $# -eq 0 ]; then
		while read stash; do
			stash_status_single "$stash" "$work_tree"
		done < <(find "$stash" -mindepth 1 -maxdepth 1 -type d)
	else
		stash_status_single "$stash/$1" "$work_tree"
	fi
}


##############
# rm command #
##############

stash_rm_usage() {
	cat <<- EOF
	$APP_NAME rm stash_name
	    remove a stash directory from the stash
	EOF
}

stash_rm() {
	[ $# -eq 1 ] || die "$(stash_rm_usage)"
	local stash_name="$1"
	local work_tree="$(canonicalize_work_tree)"
	local stash="$(canonicalize_stash)"
	local stash_dir="$stash/$stash_name"
	[ -d "$stash_dir" ] || die "$stash is not a stash"
	stash_unlink "$stash_name" 
	rm -rf "$stash_dir"
}


#################
# stash command #
#################

stash_stash_usage() {
	cat <<-EOF
	$APP_NAME stash [stash_name]
	    display the path to the stash directory, ot to the stash
	    directory of a given stash if a stash name is provided
	EOF
}

stash_stash() {
	[ $# -gt 1 ] || die "$(stash_stash_usage)"
	local stash="$(canonicalize_stash)"
	if [ $# -eq 0]; then 
		echo "$stash"
	else
		local stash_dir="$stash/$1"
		echo "stash_dir"
	fi
}


###################
# version command #
###################

stash_version_usage() {
	cat <<-EOF
	$APP_NAME version
	    display $APP_NAME version
	EOF
}

stash_version() {
	echo "$APP_NAME 0.0.1"
}


################
# help command #
################

stash_usage_usage() {
	cat <<- EOF
	$APP_NAME help
	    display this help message 
	EOF
}

stash_usage() {
	echo "$APP_NAME, a link management utility"
	echo "stash stash: $STASH_DIR"
	echo "work tree: $STASH_WORK_TREE"
	echo "usage:"
	stash_link_usage
	stash_unlink_usage
	stash_status_usage
	stash_rm_usage
	stash_version_usage
	stash_usage_usage
}

is_cmd=0;
while [ $# -ne 0 -a $is_cmd -eq 0 ]; do
	case $1 in
		--stash)
			shift
			STASH_DIR="$1"
			shift
			;;
		--work-tree)
			shift
			WORK_TREE="$1"
			shift
			;;
		-h|--help)
			stash_usage
			exit 0
			;;
		-v|--version)
			stash_version
			exit 0
			;;
		-*)
			"unknown argument: $1"
			shift
			exit 1
			;;
		*)
			is_cmd=1;	
			;;
	esac

done

[ $# -eq 0 ] && die "$(stash_usage)"

cmd="$1"
shift

case "$cmd" in
	link)
		stash_link "$@"
		;;
	unlink)
		stash_unlink "$@"
		;;
	status)
		stash_status "$@"
		;;
	rm)
		stash_rm "$@"
		;;
	cd)
		stash_cd "$@"
		;;
	version)
		stash_version
		;;
	help)
		stash_usage
		;;
	*)
		die "$(stash_usage)"
		;;
esac

exit 0
