package js.browser.events;

typedef Event = {
    function addListener(callback : haxe.Constraints.Function) : Void;
	function removeListener(callback : haxe.Constraints.Function) : Void;
	function hasListener(callback : haxe.Constraints.Function) : Bool;
}