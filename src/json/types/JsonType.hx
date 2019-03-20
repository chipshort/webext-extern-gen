package json.types;

typedef JsonType = {
    > JsonTypeDecl,
    id : String,
    ?description : String
    //TODO: isInstanceOf
    //additionalProperties
}