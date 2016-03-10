#!/bin/bash

clean="yes"
doc="yes"

for opt in $*; do
  case $opt in
    noclean) clean="no"
    ;;
    nodoc) doc="no"
    ;;
    *) echo "Unknown option: $opt"
  esac
done

# by default, we clean npm cache first
if test "$clean" = "yes"; then
  echo ">>> cleaning npm cache ..."
  echo "    You may use './build.sh noclean' to avoid cleaning npm cache"
  npm cache clean
fi

rm -rf ./dist/*

if [ ! -e dist/node_modules ]; then
  mkdir -p dist/node_modules
fi

PROJS="base center entity entity-store hub hub-center-shared message session-manager store workflow demo"

for P in $PROJS; do
  echo ">>> copying $P"
  tar -c --exclude node_modules $P | tar -x -C ./dist/node_modules
  mv ./dist/node_modules/$P ./dist/node_modules/hope-$P
done


echo ">>> creating package.json"
node merge_deps.js $PROJS


echo ">>> install npm packages"
cd ./dist
npm install
cd -


echo ">>> ui widgets"
cd ./ui-widgets
rm -rf node_modules/*
npm install
gulp build
cd -
mkdir -p ./dist/node_modules/ui-widgets
cp ./ui-widgets/{specs.js,plugins-specs.json} ./dist/node_modules/ui-widgets

echo ">>> ui dev"
cd ./ui-dev
rm -rf node_modules/*
npm install
npm link ../ui-widgets
bower --allow-root install
rm -rf ./public
NODE_ENV=production gulp build
cd -
mkdir -p ./dist/node_modules/ui-dev
cp -r ./ui-dev/public ./dist/node_modules/ui-dev/.


echo ">>> ui user"
cd ./ui-user
rm -rf node_modules/*
npm install
npm link ../ui-widgets
bower --allow-root install
rm -rf ./public
NODE_ENV=production gulp build
cd -
mkdir -p ./dist/node_modules/ui-user
cp -r ./ui-user/public ./dist/node_modules/ui-user/.


echo ">>> demo"
rm -rf ./dist/node_modules/hope-demo/center/appbundle/*

echo ">>> doc"

if test "$doc" = "yes"; then
  cd ./doc/framework
  npm install
  NODE_ENV=production gulp build
  cd ..
  ./gen_doc.sh
  cd ..
else
  rm -f ./dist/start_doc.sh
fi

mkdir ./dist/node_modules/doc
cp -r ./doc/html ./dist/node_modules/doc/.


# app developer
APPDEV="./dist/node_modules/doc/html/app-dev/"

mkdir ./tmp
cp -r ./doc/framework/public/{css,fonts,images,js,index.html} ./tmp
mv $APPDEV ./tmp/doc
mv ./tmp $APPDEV



echo ">>> scripts"
cp -r ./build/* ./dist
chmod ugo+x ./dist/center ./dist/hub ./dist/run_demo ./dist/start_edison_demo.sh ./dist/start_mock_demo.sh

