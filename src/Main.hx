
import lazy.Lazy;
import lazy.List;
import haxe.Json;
import json.JsonFix;
import json.types.JsonNamespace;
import hx.files.*;

using lazy.ListTools;
using lazy.LambdaTools;
using StringTools;

class Main {
	static var OUTPUT_FOLDER = Dir.of("output");
	static var SCHEMAS_FOLDER = Dir.of("schemas");
	static var PREDEFINED_FOLDER = Dir.of("predefined");

	static function main() {
		//FIXME: fix keywords (like import) somehow, not yet sure how
		var parsed = SCHEMAS_FOLDER.listFiles().toList()
			.filter(function (file) return file.path.filenameExt == "json")
			.map(parseFile)
			.map(lazy.ListTools.toList)
			.foldr(lazy.ListTools.concat.lazify2(), lazy.Lazy.lazify(Empty)).get()
			.filter(function (ns) return ns.namespace != "manifest");

		var namespaces = joinNamespaces(parsed);

		//FIXME: temporary hack
		namespaces = namespaces.filter(function (ns) return ns.namespace.indexOf(".") == -1);
		
		//collect predefined types
		var predefined = [];
		PREDEFINED_FOLDER.walk(function (file) {
			var dotPath = pathToDotPath(file.path);
			predefined.push(dotPath);
		}, function (dir) return true);		

		var declarations = new TypeGenerator(namespaces, predefined).generate();

		//print out generated types
		OUTPUT_FOLDER.delete(true);
		PREDEFINED_FOLDER.copyTo(OUTPUT_FOLDER.path);

		var printer = new haxe.macro.Printer("\t");
		for (decl in declarations) {
			var folder = OUTPUT_FOLDER.path.join(decl.pack.join(OUTPUT_FOLDER.path.dirSep));
			var file = File.of(folder.join(decl.name + ".hx"));
			folder.toDir().create();
			file.writeString(printer.printTypeDefinition(decl));
		}
	}

	static function pathToDotPath(path : Path) : String {
		var predefined = PREDEFINED_FOLDER.toString(); // PREDEFINED_FOLDER/
		var str = path.normalize().toString();
		if (str.startsWith(predefined))
			str = str.substr(predefined.length);
		if (path.filenameExt != "")
			str = str.substr(0, str.length - path.filenameExt.length - 1); // .filenameExt
		
		return str.replace(path.dirSep, ".");
	}

	static function joinNamespaces(namespaces : List<JsonNamespace>) : List<JsonNamespace> {
		var packages = new Map<String, List<JsonNamespace>>();

		function addToBucket(name, ns) {
			var currentBucket = packages.get(name);
			if (currentBucket == null)
				packages.set(name, [ns]);
			else
				packages.set(name, Cons(ns, currentBucket));
		}
		for (ns in namespaces) {
			var ns = ns.g();
			addToBucket(ns.namespace, ns);
			
			// var path = ns.namespace.split(".");
			// if (path.length > 1) {

			// 	var props = {};
			// 	for (fun in ns.functions) {
			// 		Reflect.setField(props, fun.name, )
			// 	}

			// 	addToBucket(path[0], {
			// 		namespace: path[0],
			// 		types: [{
			// 			id: path[1],
			// 			type: "object",
			// 			properties: ns.types,

			// 		}]
			// 	})
			// }
		}
		var namespaces = Empty;
		for (pack in packages) {
			function concatArrays<T>(a:Lazy<Array<T>>, b:Lazy<Array<T>>):Lazy<Array<T>> {
				if (a.g() == null)
					return b;
				return a.g().concat(b);
			}
			function merge(base: Dynamic, ext: Dynamic) : Lazy<Dynamic> {
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
				.foldr(function (a, b) return a.g() + "\r\n" + b.g(), "").get(); //add all docs
			var events = pack.map(function (ns) return ns.events).foldr(concatArrays, []).get().toArray();
			var types = pack.map(function (ns) return ns.types).foldr(concatArrays, []).get().toArray();
			var funcs = pack.map(function (ns) return ns.functions).foldr(concatArrays, []).get().toArray();
			var props = pack.map(function (ns) return ns.properties).foldr(merge, {}).get();
			
			var nses = namespaces;
			namespaces = Cons({
				namespace: pack.head().g().namespace,
				description: desc,
				events: events,
				types: types,
				functions: funcs,
				properties: props
				//TODO: maybe add permissions too, if I find a use for it
			}, nses);
		}

		return namespaces;
	}

	static function parseFile(file : File) {
		var content = file.readAsString();
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
}
