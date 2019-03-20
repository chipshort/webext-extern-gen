package json.types;

typedef JsonEvent = {
    > JsonFunction,
    ?extraParameters : Array<JsonFunctionParameter>
}