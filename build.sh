#!/bin/sh

git checkout master examples
jekyll build
git pull --commit origin gh-pages
git commit -am "JEKYLL BUILD"
git push origin gh-pages
