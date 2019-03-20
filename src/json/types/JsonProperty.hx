package json.types;

typedef JsonProperty = {
    > JsonTypeDecl,
    ?description : String,
    ?value : Dynamic,
    ?optional : Bool
}