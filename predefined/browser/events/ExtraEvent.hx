package browser.events;

typedef ExtraEvent<T, U> = {
	function addListener(callback : T, extraParameters : U) : Void;
	function removeListener(callback : T) : Void;
	function hasListener(callback : T) : Bool;
}