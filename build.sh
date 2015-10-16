#! /bin/bash

source ~/.nvm/nvm.sh

# go to master and build the app
git checkout master
git pull
nvm use
sed -i 's/"analytics":[ ]*""/"analytics": "UA-21342779-11"/g' src/jade_options.json
./node_modules/.bin/cake build
echo "Update gh-pages to mconf/api-mate@`git rev-parse HEAD`" > .gh-pages-update
git checkout src/jade_options.json
cp -r lib/ dist/

# back to gh-pages and organize the compiled app
git checkout gh-pages
git rm -r vendor/
git rm -r img/
git rm -r fonts/
mv dist/* .
mv api_mate.html index.html

# commit the changes
git add index.html api_mate.css api_mate.js application.css application.js
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
