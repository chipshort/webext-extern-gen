
import haxe.macro.Expr;

using StringTools;

class TypeHelper {
    static var RESERVED = ["break", "case", "cast", "catch", "class", "continue", "default", "do", "dynamic",
		"else", "enum", "extends", "extern", "false", "for", "function",
		"if", "implements", "import", "in", "inline", "interface", "null", "override", "package", "private", "public",
		"return", "static", "super", "switch", "this", "throw", "true", "try", "typedef", "untyped", "using",
		"var", "while"];
	public static function escapeName(field : Field) {
		if (RESERVED.indexOf(field.name) > 0) {
			var old = field.name;
			field.name = "_" + field.name;
			if (field.meta == null)
				field.meta = [];
			
			field.meta.push({ name: ":native", params: [valueToConstExpr(old)], pos: null});
		}
		return field;
	}

    public static function valueToField(value : Dynamic) : Field {
        var name = switch (Type.typeof(value)) {
            case TInt: "VAL_" + value;
            case TFloat: "VAL_" + Std.string(value).replace(".", "_");
            case TBool: Std.string(value).toUpperCase();
            case TClass(String): value.toUpperCase();
            default: Std.string(value).toUpperCase();
        }
        
        return {
            name: name,
            kind: FVar(null, valueToConstExpr(value)),
            pos: null
        };

        return null;
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