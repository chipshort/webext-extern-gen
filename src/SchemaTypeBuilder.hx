#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using StringTools;
using Lambda;

class SchemaTypeBuilder
{
    public static function build(ref:String, namespace:String, type:String):haxe.macro.Type
    {
        var content = sys.io.File.getContent(ref);
        //remove comments at the top
        while (content.startsWith("//"))
            content = content.substr(content.indexOf("\n") + 1);
        
        var schema : Array<JsonNamespace> = JsonFix.fixSpecialChars(haxe.Json.parse(content));
        for (ns in schema) {
            if (ns.namespace != namespace)
                continue;
            
            var type:ComplexType = parseType(ns.types.find(function (t) return t.id == type));
            return haxe.macro.ComplexTypeTools.toType(type);
        }

        return null;
    }

    static function parseType(schema:Dynamic):ComplexType
    {
        return switch (schema.type)
        {
            case "integer":
                macro : Int;
            case "number":
                macro : Float;
            case "string":
                macro : String;
            case "boolean":
                macro : Bool;
            case "array":
                parseArrayType(schema);
            case "object":
                parseObjectType(schema);
            case unknown:
                throw "Unsupported JSON-schema type: " + unknown;
        };
    }

    static function parseArrayType(schema:Dynamic):ComplexType
    {
        var type = if (Reflect.hasField(schema, "items"))
            parseType(schema.items);
        else
            macro : Dynamic;

        return macro : Array<$type>;
    }

    static function parseObjectType(schema:Dynamic):ComplexType
    {
        if (Reflect.hasField(schema, "properties"))
        {
            var required:Array<String> = Reflect.hasField(schema, "required") ? schema.required : [];
            var fields:Array<Field> = [];
            var props = schema.properties;
            for (field in Reflect.fields(props))
            {
                var meta = [];
                if (!Lambda.has(required, field))
                    meta.push({name: ":optional", params: [], pos: Context.currentPos()});
                var subschema = Reflect.field(props, field);
                fields.push({
                    name: field,
                    pos: Context.currentPos(),
                    kind: FVar(parseType(subschema)),
                    meta: meta
                });
            }
            return TAnonymous(fields);
        }

        return macro : Dynamic<Dynamic>;
    }
}
#end