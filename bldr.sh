#release build script
xcodebuild -target rhpnotifier -configuration Release -sdk macosx10.5 OBJROOT=build SYMROOT=build OTHER_CFLAGS=""
