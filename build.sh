#! /bin/bash

source ~/.nvm/nvm.sh

git checkout master
git pull
nvm use
cake build
echo "Update gh-pages to mconf/api-mate@`git rev-parse HEAD`" > .gh-pages-update
cp -r lib/ dist/

git checkout gh-pages
git rm -r vendor/
git rm -r img/
git rm -r fonts/
mv dist/* .
mv api_mate.html index.html

git add index.html api_mate.css api_mate.js
if [ -d "vendor" ]; then
    git add vendor/
fi
if [ -d "img" ]; then
    git add img/
fi
if [ -d "fonts" ]; then
    git add fonts/
fi

git commit --file=.gh-pages-update

# cleanup
rm -r lib/
rm -r dist/
rm .gh-pages-update

echo "Done. Now push it!"
