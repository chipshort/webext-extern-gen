package internal;

/** An object which allows the addition and removal of listeners for a Chrome event. **/
typedef ExtraEvent2<T, U, V> = {
	/**
		Registers an event listener <em>callback</em> to an event.
	**/
	function addListener(callback : T, extraParameter1 : U, extraParameter2 : V) : Void;
	/**
		Deregisters an event listener <em>callback</em> from an event.
	**/
	function removeListener(callback : T) : Void;
	function hasListener(callback : T) : Bool;
}