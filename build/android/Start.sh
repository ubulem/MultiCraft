#!/bin/bash -e

if [ ! -d gradle ]; then
	echo "Run this in build/android"
	exit 1
fi

FOLDER=$(pwd)/app/src/main/assets
DEST=$(mktemp -d)

echo
echo "=> Creating Assets:"

for dir in builtin textures client; do
	cp -r ../../$dir $DEST/
done

mkdir -p $DEST/fonts
cp ../../fonts/Retron2000.ttf $DEST/fonts/ # no PNG fonts because freetype

cp -r native/deps/Android/Irrlicht/shaders $DEST/client/shaders/Irrlicht

echo
echo "* Converting locale files:"
pushd ../../po
for lang in *; do
	[ ${#lang} -ne 2 ] && continue
	mopath=$DEST/locale/$lang/LC_MESSAGES
	mkdir -p $mopath
	pushd $lang
	for fn in *.po; do
		msgfmt -o $mopath/${fn/.po/.mo} $fn
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

mkdir -p $FOLDER

echo
echo "** Creating Files.zip"
ZIPDEST=$FOLDER/Files.zip
rm -f $ZIPDEST
cd $DEST; zip -0qr $ZIPDEST -- *
cd $FOLDER; rm -rf $DEST

###########

cd ../../../../../..

echo "*** Creating games.zip"
if [ -d games/default/files ]; then
	ZIPDEST=$FOLDER/games.zip
	rm -f $ZIPDEST
	zip -0qr $ZIPDEST -- games
else
	echo "You forgot to clone with submodules!"
fi

echo
echo "*** All done! You can continue in Android Studio! ***"
