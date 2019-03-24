
import json.types.JsonNamespace;
import haxe.macro.Expr;

using StringTools;
using ArrayTools;

class TypeHelper {
    static var RESERVED = ["break", "case", "cast", "catch", "class", "continue", "default", "do", "dynamic",
		"else", "enum", "extends", "extern", "false", "for", "function",
		"if", "implements", "import", "in", "inline", "interface", "null", "override", "package", "private", "public",
		"return", "static", "super", "switch", "this", "throw", "true", "try", "typedef", "untyped", "using",
		"var", "while"];
	public static function escapeName(field : Field) {
		var old = field.name;
		if (RESERVED.indexOf(field.name) > 0)
			field.name = "_" + field.name;
		
		if (field.meta == null)
				field.meta = [];
		field.name = field.name.replace("-", "_");
		if (field.name != old)
			field.meta.push({ name: ":native", params: [valueToConstExpr(old)], pos: null});
		
		return field;
	}

	/** Joins all namespaces with the same `namespace` together **/
    public static function joinNamespaces(namespaces : Array<JsonNamespace>) : Array<JsonNamespace> {
        var packages = new Map<String, Array<JsonNamespace>>();

        function addToBucket(name, ns) {
            var currentBucket = packages.get(name);
            if (currentBucket == null)
                packages.set(name, [ns]);
            else
                currentBucket.push(ns);
        }
        for (ns in namespaces)
            addToBucket(ns.namespace, ns);
        
        var namespaces = [];
        for (pack in packages) {
            function merge(base: Dynamic, ext: Dynamic) : Dynamic {
                if (ext == null)
                    return base == null ? {} : base;
                if (base == null)
                    return ext == null ? {} : ext;
                var res = Reflect.copy(base);
                for(f in Reflect.fields(ext))
                    Reflect.setField(res,f,Reflect.field(res,f));
                return res;
            }
            var desc = pack.map(function (ns) return ns.description)
                .foldl(function (a, b) return a + "\r\n" + b, ""); //add all docs
            var events = pack.map(function (ns) return ns.events).foldl(ArrayTools.concat, []);
            var types = pack.map(function (ns) return ns.types).foldl(ArrayTools.concat, []);
            var funcs = pack.map(function (ns) return ns.functions).foldl(ArrayTools.concat, []);
            var props = pack.map(function (ns) return ns.properties).foldl(merge, {});
            var permissions = pack.map(function (ns) return ns.permissions).foldl(ArrayTools.concat, []).distinct();
            
            namespaces.push({
                namespace: pack.head().namespace,
                description: desc,
                events: events,
                types: types,
                functions: funcs,
                properties: props,
                permissions: permissions
            });
        }

        return namespaces;
    }

	public static function addPermissionsToDoc(desc : Null<String>, permissions : Null<Array<String>>) {
		var doc = desc == null ? "" : desc;
		if (permissions != null)
			doc += "\nNEEDED PERMISSIONS: " + permissions.join(", ");
		return doc;
	}

    public static function enumValueToField(value : Dynamic) : Field {
		var doc = null;
        var name = switch (Type.typeof(value)) {
            case TInt: "VAL_" + value;
            case TFloat: "VAL_" + Std.string(value).replace(".", "_");
            case TBool: Std.string(value).toUpperCase();
            case TClass(String): value.toUpperCase();
			case TObject if (value.name != null):
				doc = value.description;
				value.name.toUpperCase();
            default: Std.string(value).toUpperCase();
        }
        
        return {
            name: name,
            kind: FVar(null, valueToConstExpr(value)),
            pos: null,
			doc: doc
        };
    }

	public static function makeStatic(field : Field) {
		if (field.access == null)
			field.access = [];
		
		field.access.push(AStatic);
		return field;
	}

	public static function valueToConstExpr(value : Dynamic) {
		return {expr: EConst(
			switch (Type.typeof(value)) {
				case TInt: CInt(value);
				case TFloat: CFloat(value);
				case TBool: CIdent(value);
				case TClass(String): CString(value);
				default: CIdent("null");
			}), pos: null };
	}
}