package json.types;

typedef JsonTypeDecl = {
    ?type : String,
    ?_ref : String, //only if no type is given, note: this is $ref in the json files
    ?items: JsonTypeDecl, //only for type = "array"
    ?properties : Dynamic, //only for type = "object"
    ?choices : Array<JsonTypeDecl>, //only if no type and no $ref is given
    ?async : Dynamic, //only for type = "function" //TODO: add abstract for this
    ?parameters : Array<JsonFunctionParameter>, //only for type = "function"
    ?returns : JsonTypeDecl, //only for type = "function"
    ?unsupported : Bool
}