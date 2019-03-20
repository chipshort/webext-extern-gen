package chrome.events;

typedef Event<T> = {
    function addListener(callback : T) : Void;
	function removeListener(callback : T) : Void;
	function hasListener(callback : T) : Bool;
}