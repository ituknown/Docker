#!/bin/sh

echo "remove _book ..."
rm -rf _book
echo "remove _book success!"

echo -e "\n"

echo "remove node_modules ..."
rm -rf node_modules
echo "remove node_modules seccess!"

echo -e "\n"

echo "begin install gitbook plugins ..."

echo -e "\n"

gitbook install --log=debug

echo "Congratulations! plugins install Success"

echo -e "\n"

echo "Now will run service with gitbook serve, if start fail you need Respecify a port !!!!"

gitbook serve
