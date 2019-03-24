#!/bin/sh

if ! [ -x "$(command -v python2)" ]; then
  echo 'Error: Python2 is not installed.' >&2
  exit 1
fi
if ! [ -x "$(command -v haxe)" ]; then
  echo 'Error: Haxe is not installed.' >&2
  exit 1
fi

set -e
echo "Installing Haxelib dependencies..."
haxelib install build.hxml --always
echo "----------"

#Convert chrome idl schemas
python2 chromium_idl_converter/haxe_gen.py
echo "----------"

#Generate Haxe externs
haxe build.hxml -D chrome