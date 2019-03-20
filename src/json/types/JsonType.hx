package json.types;

typedef JsonType = {
    id : String,
    type : String, //TODO: make abstract for this
    ?description : String,
    ?enum_ : Array<String>, //This should be enum, but that's a keyword, so this is fixed when parsing
    ?properties : Dynamic,
    //TODO: isInstanceOf
    //additionalProperties
}