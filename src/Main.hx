
import lazy.List;
import haxe.Json;
import JsonNamespace;
import HaxeType;
import haxe.macro.Expr;

using lazy.ListTools;
using lazy.LambdaTools;
using StringTools;

class Main {
	static function main() {
		var parsed = sys.FileSystem.readDirectory("schemas").toList()
			.filter(function (file) return file.endsWith(".json"))
			.map(function (file) return "schemas/" + file)
			.map(parseFile)
			.map(lazy.ListTools.toList)
			.foldr(lazy.ListTools.concat.lazify2(), lazy.Lazy.lazify(Empty)).get()
			.filter(function (ns) return ns.namespace != "manifest");

		for (p in parsed) {
			trace(p.get().namespace);
			trace(p.get().types != null ? p.get().types.length : 0);
			trace(p.get().events != null ? p.get().events.length : 0);
			trace(p.get().functions != null ? p.get().functions.length : 0);
		}
		// parsed.print();

		var namespaces = parsed.map(function (ns) return ns.namespace).distinct();

		var knownTypes = new Map<String, JsonType>();

		var declarations : Array<TypeDefinition> = [];
		declarations.push({
			pack: ["js", "browser"],
			name: "Browser",
			pos: null,
			kind: TDClass(),
			fields: parsed.map(function (ns) return cast {
				name: ns.namespace,
				doc: ns.description,
				access: [AStatic, APublic],
				kind: FVar(TPath({pack: ["js", "browser"], name: toHaxeType(ns)})),
				pos: null,
			}).toArray()
		});

		// trace(new haxe.macro.Printer("\t").printTypeDefinition(declarations[0]));

		// for (ns in parsed) {
		// 	var ns = ns.g();
		// 	for (type in ns.types)
		// 		knownTypes.set(ns.namespace + "." + type.id, type);
		// 	// if (ns.event != null)
		// 	// 	for (event in ns.events)
		// 	// 		knownTypes.set(ns.namespace + "." + event.)
		// }

		// for (ns in parsed) {

		// }
	}

	static function parseFile(file) {
		var content = sys.io.File.getContent(file);
        //remove comments at the top
        while (content.startsWith("//"))
            content = content.substr(content.indexOf("\n") + 1);
		if (content.startsWith("/*"))
			content = content.substr(content.indexOf("*/") + 2);
        
		try {
			var json : Array<JsonNamespace> = JsonFix.fixSpecialChars(Json.parse(content));
			return json;
		} catch (e : Dynamic) {
			throw "Could not parse " + file + " " + e;
		}
	}

	static function toHaxeType(ns : JsonNamespace)
		return ns.namespace.charAt(0).toUpperCase() + ns.namespace.substr(1).toLowerCase();
}
