#!/bin/bash -e

if [ ! -d MultiCraft/MultiCraft.xcodeproj ]; then
	echo "Run this in build/iOS"
	exit 1
fi

FOLDER=$(pwd)
DEST=$(mktemp -d)

for dir in builtin textures client; do
	cp -r ../../$dir $DEST/
done

cp -r deps/irrlicht/shaders $DEST/client/shaders/Irrlicht

mkdir -p $DEST/fonts
cp ../../fonts/Retron2000.ttf $DEST/fonts/ # no PNG fonts because freetype
mkdir -p $DEST/games
cp -r ../../games/default $DEST/games/default
pushd ../../po
for lang in *; do
	[ ${#lang} -ne 2 ] && continue
	mopath=$DEST/locale/$lang/LC_MESSAGES
	mkdir -p $mopath
	pushd $lang
	for fn in *.po; do
		# brew install gettext
		/usr/local/Cellar/gettext/*/bin/msgfmt -o $mopath/${fn/.po/.mo} $fn
	done
	popd
done
popd

find $DEST -type d -name '.git' -print0 | xargs -0 -- rm -r
find $DEST -type f -name '.git*' -delete
find $DEST -type f -name '.DS_Store' -delete

# remove broken languages
for broken_lang in ja ko he; do
	find $DEST -type d -name $broken_lang -print0 | xargs -0 -- rm -r
done

# remove unnecessary mods
#MODS=$DEST/games/default/files
#for mods in MOD_NAMES; do
#	find $DEST/games/default/files -type d -name $mods -print0 | xargs -0 -- rm -r
#done

# remove inaccessible text files
for name in settingtypes LICENSE license README COPYING; do
	find $DEST -type f -name $name".txt" -exec rm -f {} \;
	find $DEST -type f -name $name".md" -exec rm -f {} \;
done

echo "Creating assets.zip"
ZIPDEST=$FOLDER/assets.zip
rm -f $ZIPDEST

PASSWORD=$1
if [[ -z "$PASSWORD" ]]; then
    PASSWORD="1"
fi
cd $DEST; zip -P $PASSWORD -1r $ZIPDEST -- *
cd $FOLDER; rm -rf $DEST
