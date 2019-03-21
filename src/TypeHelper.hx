
import haxe.macro.Expr;

using StringTools;

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

		// var regex = ~/[a-zA-Z_][a-zA-Z0-9_]*/;
		// if (!regex.match(field.name) || regex.matchedPos().len != field.name.length)
		// 	trace(field.name);
		
		return field;
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