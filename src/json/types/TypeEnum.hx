package json.types;

@:enum abstract TypeEnum(String) {
    var String = "string";
    var Boolean = "boolean";
    var Integer = "integer";
    var Number = "number";
    var Null = "null";
    var Array = "array";
    var Object = "object";
    var Function = "function";
    var Any = "any";
}