package json.types;

typedef JsonFunction = { //TODO: is this even needed as a seperate type?
    > JsonTypeDecl,
    name : String,
    ?description : String
}