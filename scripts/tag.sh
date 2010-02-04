#!/bin/sh
# script for tagging releases

tag=$1
if [ "$tag" == "" ]; then
	echo "No tag specified"
	exit
fi

# fail unless on master branch
head=`git symbolic-ref HEAD`
if [ "$head" != "refs/heads/master" ]; then
	echo "Not on master branch. Head is $head"
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