package json.types;

typedef JsonNamespace = {
    namespace : String,
    ?description : String,
    ?permissions : Array<String>,
    ?types : Array<JsonType>,
    ?functions : Array<JsonFunction>,
    ?events : Array<JsonEvent>,
    ?properties : Dynamic
}
