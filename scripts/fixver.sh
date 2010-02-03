tag=$1
if [ "$tag" == "" ]; then
	echo "No tag specified"
	exit
fi

sed -i "" 's/__VERSION__/'$tag'/g' rhpnotifier-Info.plist
sed -i "" 's/__VERSION__/'$tag'/g' */Credits.html
