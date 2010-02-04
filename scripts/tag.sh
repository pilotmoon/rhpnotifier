#!/bin/sh
# script for tagging releases on the master branch
tag=$1
if [ "$tag" == "" ]; then
	echo "No tag specified"
	exit
fi

# bump project version
agvtool next-version -all
git commit -a -m "Increment project version for tag $tag"

# apply tag
git tag -m "Tag for $tag" -a $tag

# bump agv again so number is unique for tag
agvtool next-version -all
git commit -a -m "Increment project version following tag $tag"

# update remote repos
git push origin master
git push --tags