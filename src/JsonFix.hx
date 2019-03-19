
using StringTools;

class JsonFix {

    static var replacementMap = [
        "enum" => "enum_",
        "$" => "_"
    ];

    public static function fixSpecialChars(json : Dynamic) {
        if (Std.is(json, Array)) {
            var a : Array<Dynamic> = json;
            for (e in a)
                fixSpecialChars(e);
        }
        else {
            for (field in Reflect.fields(json)) {
                var value = Reflect.field(json, field);
                fixSpecialChars(value);
                var newField = field;
                //fix field name
                for (str in replacementMap.keys())
                    newField = newField.replace(str, replacementMap.get(str));
                //set correct value for new field
                if (newField != field)
                    Reflect.setField(json, newField, value);
            }
        }
        return json;
    }
}