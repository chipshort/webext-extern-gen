

typedef JsonNamespace = {
    namespace : String,
    ?description : String,
    ?permissions : Array<String>,
    ?types : Array<JsonType>,
    ?functions : Array<JsonFunction>,
    ?events : Array<Dynamic>
}

typedef JsonType = {
    id : String,
    type : String, //TODO: make abstract for this
    ?description : String,
    /*?enum : Array<String>*/
    ?enum_ : Array<String>, //This should be enum, but that's a keyword, so this is fixed when parsing
    ?properties : Dynamic
}

typedef JsonFunction = {
    name : String,
    type : String,
    ?description : String,
    ?async : String, //TODO: add abstract for this
    parameters : Array<Dynamic>
}

typedef JsonFunctionParameter = {
    type : String,
    name: String,
    ?optional: Bool,
    ?parameters: Array<JsonFunctionParameter>,
    ?_ref : String //This should be $ref, but that's not a valid 
}