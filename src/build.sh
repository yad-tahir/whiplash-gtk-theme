#!/bin/bash

TMP='/tmp/flat-remix-gtk'
VARIANTS=(Blue Red Teal Green Yellow Pink)
VARIANT_COLORS=('#00f5ff' '#ff4422' '#00ff7f' '#a7e23e' '#ffa500' '#da70d6')
VARIANT_SELECTED_FONT_COLORS=('black' 'white' 'black' 'black' 'black' 'black')
DEFAULT_COLOR='#367bf0'

function generate_variant_template {
	variant="$1"
	variant_name="$2"
	variant_color="$3"
	variant_selected_font_color="$4"
	for theme in variant-templates/*
	do
		theme_basename="$(basename "$theme")"
		variant_dir="$TMP/${variant_name}${theme_basename#Flat-Remix-GTK}"
		cp -a "$theme" "$variant_dir"
		find "$variant_dir" -type f -exec sed "s/${DEFAULT_COLOR}/${variant_color}/gi" -i {} \;
		sed "s/selected_fg_color: #ffffff/selected_fg_color: $variant_selected_font_color/" -i "$variant_dir"/gtk-2.0/gtkrc
		sed -e "s/Flat-Remix-GTK/${variant_name}/g" \
			-e "s/IconTheme=Flat-Remix/IconTheme=Flat-Remix-${variant}${icon_variant}/" \
			-i "$variant_dir/index.theme"
	done
}

function generate_css_files { (
	variant_name="$1"
	variant_color="$2"
	variant_selected_font_color="$3"
	mkdir -p "$TMP/css/$variant_name"
	cd sass || return
	for scss in *.scss
	do
		echo -e "Generate $variant_name \t $scss"
		echo "\$selected_bg_color: $variant_color; \$selected_fg_color: ${variant_selected_font_color};" | \
				cat - "$scss" | \
				scss --sourcemap=none -C -q -s "$TMP/css/$variant_name/$(basename "${scss%%.scss}")".css &
	done
	wait
) }

function copy_css_files {
	variant_name="$1"
	cp "$TMP/css/${variant_name}/gtk.css" "$TMP/${variant_name}/gtk-3.0/gtk.css"
	cp "$TMP/css/${variant_name}/gtk-solid.css" "$TMP/${variant_name}-Solid/gtk-3.0/gtk.css"

	cp "$TMP/css/${variant_name}/gtk-dark.css" "$TMP/${variant_name}/gtk-3.0/gtk-dark.css"
	cp "$TMP/css/${variant_name}/gtk-dark.css" "$TMP/${variant_name}-Dark/gtk-3.0/gtk.css"
	cp "$TMP/css/${variant_name}/gtk-dark.css" "$TMP/${variant_name}-Darker/gtk-3.0/gtk-dark.css"
	cp "$TMP/css/${variant_name}/gtk-dark-solid.css" "$TMP/${variant_name}-Solid/gtk-3.0/gtk-dark.css"
	cp "$TMP/css/${variant_name}/gtk-dark-solid.css" "$TMP/${variant_name}-Dark-Solid/gtk-3.0/gtk.css"
	cp "$TMP/css/${variant_name}/gtk-dark-solid.css" "$TMP/${variant_name}-Darker-Solid/gtk-3.0/gtk-dark.css"

	cp "$TMP/css/${variant_name}/gtk-darker.css" "$TMP/${variant_name}-Darker/gtk-3.0/gtk.css"
	cp "$TMP/css/${variant_name}/gtk-darker-solid.css" "$TMP/${variant_name}-Darker-Solid/gtk-3.0/gtk.css"

	cp "$TMP/css/${variant_name}/gtk-darkest.css" "$TMP/${variant_name}-Darkest/gtk-3.0/gtk.css"
	cp "$TMP/css/${variant_name}/gtk-darkest-solid.css" "$TMP/${variant_name}-Darkest-Solid/gtk-3.0/gtk.css"
	cp "$TMP/css/${variant_name}/gtk-darkest-noBorder.css" "$TMP/${variant_name}-Darkest-NoBorder/gtk-3.0/gtk.css"
	cp "$TMP/css/${variant_name}/gtk-darkest-solid-noBorder.css" "$TMP/${variant_name}-Darkest-Solid-NoBorder/gtk-3.0/gtk.css"


	cp "$TMP/css/${variant_name}/cinnamon.css" "$TMP/${variant_name}/cinnamon/cinnamon.css"
	cp "$TMP/css/${variant_name}/cinnamon-solid.css" "$TMP/${variant_name}-Solid/cinnamon/cinnamon.css"

	cp "$TMP/css/${variant_name}/cinnamon-darker.css" "$TMP/${variant_name}-Darker/cinnamon/cinnamon.css"
	cp "$TMP/css/${variant_name}/cinnamon-darker-solid.css" "$TMP/${variant_name}-Darker-Solid/cinnamon/cinnamon.css"

	cp "$TMP/css/${variant_name}/cinnamon-dark.css" "$TMP/${variant_name}-Dark/cinnamon/cinnamon.css"
	cp "$TMP/css/${variant_name}/cinnamon-dark-solid.css" "$TMP/${variant_name}-Dark-Solid/cinnamon/cinnamon.css"

	cp "$TMP/css/${variant_name}/cinnamon-darkest.css" "$TMP/${variant_name}-Darkest/cinnamon/cinnamon.css"
	cp "$TMP/css/${variant_name}/cinnamon-darkest.css" "$TMP/${variant_name}-Darkest-NoBorder/cinnamon/cinnamon.css"
	cp "$TMP/css/${variant_name}/cinnamon-darkest-solid.css" "$TMP/${variant_name}-Darkest-Solid/cinnamon/cinnamon.css"
	cp "$TMP/css/${variant_name}/cinnamon-darkest-solid.css" "$TMP/${variant_name}-Darkest-Solid-NoBorder/cinnamon/cinnamon.css"
}

function generate_assets {
	variant_name="$1"
	variant_color="$2"
	mkdir -p "$TMP/assets-renderer"
	cp -r assets-renderer "$TMP/assets-renderer/$variant_name"
	find "$TMP/assets-renderer/$variant_name" -type f -exec sed "s/${DEFAULT_COLOR}/${variant_color}/gi" -i {} \;
	"$TMP"/assets-renderer/"$variant_name"/gtk2/render-assets.sh &
	"$TMP"/assets-renderer/"$variant_name"/gtk3/render-assets.sh &
	"$TMP"/assets-renderer/"$variant_name"/metacity/render-assets.sh &
	"$TMP"/assets-renderer/"$variant_name"/xfwm4/render-assets.sh &
	wait

	for theme in "$TMP/$variant_name"*
	do
		case "$theme" in
			*Darkest*)
				cp "$TMP"/assets-renderer/"$variant_name"/gtk2/assets-darkest/* "$theme"/gtk-2.0/assets/
				cp "$TMP"/assets-renderer/"$variant_name"/metacity/metacity-darkest/* "$theme"/metacity-1/
				if [[ "$theme" == *NoBorder* ]]
					then cp "$TMP"/assets-renderer/"$variant_name"/xfwm4/assets-darkest-noBorder/* "$theme"/xfwm4/
					else cp "$TMP"/assets-renderer/"$variant_name"/xfwm4/assets-darkest/* "$theme"/xfwm4/
				fi
				;;
			*Dark|*Dark-*)
				cp "$TMP"/assets-renderer/"$variant_name"/gtk2/assets-dark/* "$theme"/gtk-2.0/assets/
				cp "$TMP"/assets-renderer/"$variant_name"/metacity/metacity-dark/* "$theme"/metacity-1/
				cp "$TMP"/assets-renderer/"$variant_name"/xfwm4/assets-dark/* "$theme"/xfwm4/
				;;
			*Darker|*Darker-*)
				cp "$TMP"/assets-renderer/"$variant_name"/gtk2/assets/* "$theme"/gtk-2.0/assets/
				cp "$TMP"/assets-renderer/"$variant_name"/metacity/metacity-darkest/* "$theme"/metacity-1/
				cp "$TMP"/assets-renderer/"$variant_name"/xfwm4/assets-darkest-noBorder/* "$theme"/xfwm4/
				;;
			*)
				cp "$TMP"/assets-renderer/"$variant_name"/gtk2/assets/* "$theme"/gtk-2.0/assets/
				cp "$TMP"/assets-renderer/"$variant_name"/metacity/metacity/* "$theme"/metacity-1/
				cp "$TMP"/assets-renderer/"$variant_name"/xfwm4/assets/* "$theme"/xfwm4/
				;;
		esac
		cp "$TMP"/assets-renderer/"$variant_name"/gtk2/menubar-toolbar/* "$theme"/gtk-2.0/menubar-toolbar/
		cp "$TMP"/assets-renderer/"$variant_name"/gtk3/assets/* "$theme"/gtk-3.0/assets/
		cp "$TMP"/assets-renderer/"$variant_name"/cinnamon/* "$theme"/cinnamon/assets/
	done
}

function generate_variant {
	variant="$2"
	variant_name="$3"
	variant_color="$4"
	variant_selected_font_color="$5"

	generate_variant_template "$variant" "$variant_name" "$variant_color" "$variant_selected_font_color"
	generate_css_files "$variant_name" "$variant_color" "$variant_selected_font_color"
	copy_css_files "$variant_name"
	[[ $1 != "--no-assets" ]] && generate_assets "$variant_name" "$variant_color"
	cp -a "$TMP/$variant_name"* ..
}


rm -rf "$TMP"
mkdir -p "$TMP"

for i in $(seq 0 $((${#VARIANTS[*]}-1)))
do
	variant="${VARIANTS[$i]}"
	variant_name="Flat-Remix-GTK-${variant}"
	variant_color="${VARIANT_COLORS[$i]}"
	variant_selected_font_color="${VARIANT_SELECTED_FONT_COLORS[$i]}"
	generate_variant "$1" "$variant" "$variant_name" "$variant_color" "$variant_selected_font_color" &
done

wait

echo 'Done!'
