#!/bin/bash

cd `dirname $0`
ROOT="$(pwd)"
DIST="$(cd ../themes && pwd)"
TMP='/tmp/whiplash-theme'
VARIANTS=(blue red orange teal green yellow pink)
VARIANT_COLORS=('#00f5ff' '#ff0000' '#ff4422' '#00ff7f' '#a7e23e' '#ffa500' '#da70d6')
MAGIC_COLOR='#367bf0'
SCSS=$(which scss)

die() { echo "$*" 1>&2 ; exit 1; }

function generate-gtk-assets {
	local vname="$1"
	local vcolor="$2"
	local vdir="$3"

	local dir="$vdir/assets-render"
	mkdir -p "$dir" ||
		die "Cannot create directory $vname/assets-renderer"

	cp -r assets-renderer/* "$dir"

	# Add variant color by replacing the magic color
	find "$dir" -type f -exec sed "s/${MAGIC_COLOR}/${vcolor}/gi" -i {} \;

	# Execute rendering scripts.
	$dir/gtk2/render-assets.sh &
	$dir/gtk3/render-assets.sh &
	$dir/metacity/render-assets.sh &
	$dir/xfwm4/render-assets.sh &

	# Copy the output once it is ready. All the outputs are placed in $dir.
	wait
	for template in ./variant-templates/* ; do
		local tname="$(basename "$template")"
		local tag="${tname##whiplash-gtk}"
		local tdir="$vdir/whiplash-gtk-${vname}${tag}"

		# @TODO because we are copying everything, some of the asset files are
		# actually not used by theme. We can fix that by filtering out some files
		cp "$dir/gtk3/assets"/* "$tdir/gtk-3.0/assets/"
		cp "$dir/cinnamon"/* "$tdir/cinnamon/assets/"
		cp "$dir/gtk2/menubar-toolbar"/* "$tdir/gtk-2.0/menubar-toolbar/"

		# For GTK 2, xfwm4, metacity, we need to be more careful as each
		# template variation has its own assets, which are placed in different
		# directories
		cp "$dir/metacity/metacity$tag"/* "$tdir/metacity-1/"
		cp "$dir/xfwm4/assets$tag"/* "$tdir/xfwm4/"
		cp "$dir/gtk2/assets$tag"/* "$tdir/gtk-2.0/assets/"
	done
}

# Starts generating a template process.
function generate-gtk-theme {
	local vname="$1"
	local vcolor="$2"
	local vdir="$3"

	# Generate CSS files
	mkdir -p "$vdir/css" || die "Cannot create directory $vdir/css"

	# Spawn a new process to change PWD.This is required by scss
	(
		cd ./sass
		for scss in *.scss; do
			local dest="$vdir/css/$(basename "${scss%%.scss}").css"
			echo -e "Generate $vname \t $scss"
			echo "\$selected_bg_color: $vcolor; \$selected_fg_color: black;" | \
				cat - "$scss" | \
				scss --sourcemap=none -C -q \
					 -s "$vdir/css/$(basename "${scss%%.scss}")".css || \
				die "Problem occurred when generating $dest"
		done
	)
	wait

	# Generate templates
	for template in ./variant-templates/* ; do
		local tname="$(basename "$template")" # e.g. whiplash-gtk-dark
		# Abstract the tag name of the template. For example, if the template is
		# called whiplash-gtk-darker, then the tag name is -darker
		local tag="${tname##whiplash-gtk}"
		# The name of template directory is important as template directories
		# will become eventually as output directories once they are done. Any
		# variation of color and or template must be placed in a separate
		# directory. To avoid 'duplicated directory' problem that can occur in
		# user's theme directory, output directories must adhere to the
		# following syntax:
		# whiplash-gtk-<color-variant>-<template-variant>
		local tdir="$vdir/whiplash-gtk-${vname}${tag}"

		cp -a "$template" "$tdir"

		# Apply variant color by replacing the magic color
		find "$tdir" -type f -exec sed "s/$MAGIC_COLOR/$vcolor/gi" -i {} \;
		# @TODO Remove this junk and make it more generic
		sed "s/selected_fg_color: #ffffff/selected_fg_color: black/" -i "$tdir"/gtk-2.0/gtkrc
		# @TODO @IMPORTANT Icon themes are broken. Address this in the future.
		sed -e "s/whiplash-gtk/${vname}/g" \
			-e "s/IconTheme=whiplash/IconTheme=whiplash-${vname}${tname}/" \
			-i "$tdir/index.theme"

		cp "$vdir/css/gtk${tag}.css" "$tdir/gtk-3.0/gtk.css"
		cp "$vdir/css/cinnamon${tag}.css" "$tdir/cinnamon/gtk.css"
	done

	# Generate asset files
	[ "$option" != "--no-assets" ] && generate-gtk-assets "$vname" "$vcolor" "$vdir"

	# Gather final output files
	cp -a "$TMP/$vname/whiplash-gtk"* "$DIST"
}


function start {
	local option="$1"

	# Initial Checking
	[ -d "$TMP" ] && rm -rf "$TMP"; mkdir -p "$TMP"
	[ ! -d "$DIST" ] && mkdir -p "$DIST"
	[ -z "$SCSS" ] && die "SCSS cannot be found in $PATH"

	local len=${#VARIANTS[@]}
	for i in $(seq 0 $(($len-1))); do
		vname="${VARIANTS[$i]}" # e.g. red
		vcolor="${VARIANT_COLORS[$i]}" # e.g. #ff0000

		local vdir="$TMP/$vname" # e.g. /tmp/whiplash-theme/red
		[ -d "$vdir" ] && rm -rm "$vdir"
		mkdir "$vdir"

		# Generate a variant. Encoding this in a different function
		# allows us to generate multiple templates at the same time.
		generate-gtk-theme "$vname" "$vcolor" "$vdir" &
	done
}

start

wait
echo 'Done!'
