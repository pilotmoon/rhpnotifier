echo generating web content
mkdir build/web
erb templates/index.html > build/web/index.html
erb templates/rnotes.html > build/web/$tag.html

echo fixing up version numbers
sed -i "" 's/__VERSION__/'$tag'/g' rhpnotifier-Info.plist
sed -i "" 's/__VERSION__/'$tag'/g' build/web/index.html

echo building
xcodebuild -target rhpnotifier -configuration Release -sdk macosx10.5 OBJROOT=build SYMROOT=build OTHER_CFLAGS=""
