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
1. Go to https://hg.mozilla.org/mozilla-unified/tags, choose the version of Firefox you want externs for, then navigate to /browser/components/extensions/schemas/
2. Download them (as a zip) and put the files (unpacked) into the "firefox_schemas" folder within this project.
3. Run the generator using `haxe build.hxml`
4. The output can be found in "firefox_output"

### Chrome Extension
1. Go to https://chromium.googlesource.com/chromium/src/+refs, choose the version of Crhome you want externs for, then navigate to /chrome/common/extensions/api/
2. Download them (as a tgz) and put the files (unpacked) into the "chrome_schemas" folder within this project.
3. You probably need to delete a few files that do not contain api definitions and also remove comments from the files.
4. Run the generator using `haxe build.hxml -D chrome`
5. The output can be found in "chrome_output"

## TODO:
- The generated APIs are probably incomplete.
- Whenever a type is not found, it is made Dynamic,which makes it easy to get it to compile,
but is not great from a user perspective. Make the type detection more flexible, maybe?
Or: Just put the asked type in there and hope it exists (or predefine it).
Investigation on the number of missing types needed.
- Find a json parser that actually allows comments (even in the middle of the file) (tried tjson)
- Find out where the definitions for `Runtime` are in Chrome and what other definitions are missing
