package json.types;

typedef JsonTypeDecl = {
    ?type : TypeEnum,
    ?_ref : String, //only if no type is given, note: this is $ref in the json files
    ?items: JsonTypeDecl, //only for type = "array"
    ?properties : Dynamic, //only for type = "object"
    ?functions : Array<JsonFunction>, //only for type = "object"
    ?events : Array<JsonEvent>, //only for type = "object"
    ?choices : Array<JsonTypeDecl>, //only if no type and no $ref is given
    ?async : AsyncEnum, //only for type = "function"
    ?parameters : Array<JsonFunctionParameter>, //only for type = "function"
    ?returns : JsonTypeDecl, //only for type = "function"
    ?enum_ : Array<Dynamic>, //note: enum in the json files
    ?unsupported : Bool
}