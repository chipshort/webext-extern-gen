# Haxe WebExtension Externs Generator

This project aims to generate Haxe externs for writing WebExtensions compatible with Mozilla Firefox (and Chrome).
It uses the browser vendors' own json api specification files to do so.

## Installation

A [Haxe](https://haxe.org) installation is needed.

Just clone this git and run `haxelib install build.hxml`
That should install all the necessary libraries.

TODO: Make lazy lib public on haxelib or remove it from the project

## Usage

The usage depends on whether you want to generate the Firefox or Chrome Extension APIs:

### Firefox WebExtension
1. Go to https://hg.mozilla.org/mozilla-unified/tags, choose the version of Firefox you want externs for, then navigate to /browser/components/extensions/schemas/ and /toolkit/components/extensions/schemas
2. Download them (as a zip) and put the files (unpacked) into the "firefox_schemas" folder within this project.
3. Run the generator using `./generate_firefox.sh`
4. The output can be found in "firefox_output"

### Chrome Extension
1. Go to https://chromium.googlesource.com/chromium/src/+refs, choose the version of Crhome you want externs for, then navigate to /chrome/common/extensions/api/ and /extensions/common/api
2. Download them (as a tgz) and put the files (unpacked) into the "chrome_schemas" folder within this project.
3. Run the generator using `./generate_chrome.sh`
4. The output can be found in "chrome_output"

## TODO:
- Probably only needs more testing of the actual APIs
- Write a wrapper around the apis for easy portability