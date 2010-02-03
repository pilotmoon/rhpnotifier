#!/bin/sh
agvtool next-version -all
git commit -a -m "Increment CFBundleVersion"