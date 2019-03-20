package test;

import js.Browser.*;

class Main
{
    public static function main() : Void
    {
        #if chrome
        chrome.History.search({
            text: "test"
        }, function (items) {
            document.getElementById("data").innerText = Std.string(items);
        });
        #else
        browser.History.search({
            text: "test"
        }).then(function (items : Array<browser.history.HistoryItem>) {
            document.getElementById("data").innerText = Std.string(items);
        });
        #end
    }
}