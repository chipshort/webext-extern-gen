package test;

import js.browser.Browser;

class Main
{
    public static function main() : Void
    {
        Browser.bookmarks._import(function () {});
        // Browser.search.search({ tabId: 0, query: "test", engine: null});
    }
}