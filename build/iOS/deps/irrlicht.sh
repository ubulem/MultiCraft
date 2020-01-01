#!/bin/bash -e

. sdk.sh

[ ! -d irrlicht-src ] && \
	git clone -b ogl-es --depth 1 https://github.com/MoNTE48/Irrlicht irrlicht-src

cd irrlicht-src/source/Irrlicht
xcodebuild build \
	-project Irrlicht.xcodeproj \
	-configuration Release \
	-scheme Irrlicht_OSX \
	-destination 'platform=macOS,variant=Mac Catalyst'
cd ../..

[ -d ../irrlicht ] && rm -r ../irrlicht
mkdir -p ../irrlicht
cp lib/OSX/libIrrlicht.a ../irrlicht/
cp -r include ../irrlicht/include

echo "Irrlicht build successful"
