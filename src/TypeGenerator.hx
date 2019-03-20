import json.types.*;
import haxe.macro.Expr;
import TypeHelper.*;

using StringTools;

class TypeGenerator {
    var namespaces : Iterable<JsonNamespace>;
    var knownTypes = new Map<String, Bool>();
    var currentPackage : Array<String>;

    static var PACKAGE = ["browser"]; //["js", "browser"]
	static inline var NATIVE_PACK = "browser";

    public function new(namespaces : Iterable<JsonNamespace>, predefinedTypes : Iterable<String>) {
        this.namespaces = namespaces;
        //mark namespaces as known
        for (ns in namespaces) {
			if (ns.types != null)
				for (type in ns.types)
					knownTypes.set(toHaxePackage(ns.namespace) + "." + toHaxeType(type.id), true);
		}
        for (type in predefinedTypes)
            knownTypes.set(type, true);
    }

    public function generate() : Array<TypeDefinition> {
        var declarations : Array<TypeDefinition> = [];
		//main entry point
		// declarations.push({
		// 	pack: PACKAGE,
		// 	name: "Browser",
		// 	pos: null,
		// 	meta: [{ name: ":native", params: [{expr: EConst(CString(NATIVE_PACK)), pos: null}], pos: null }],
		// 	kind: TDClass(),
		// 	fields: namespaces.map(function (ns) return cast {
		// 		name: ns.namespace, //TODO: escape
		// 		doc: ns.description,
		// 		access: [AStatic, APublic],
		// 		kind: FVar(TPath({pack: PACKAGE, name: toHaxeType(ns.namespace)})),
		// 		pos: null,
		// 	}).map(escapeName).toArray()
		// });
		
		for (ns in namespaces) {
			if (ns.types != null)
				for (type in ns.types) {
					currentPackage = toHaxePackage(ns.namespace);
					declarations.push({
						pack: currentPackage,
						name: toHaxeType(type.id),
						pos: null,
						kind: TDStructure,
						fields: parseProperties(type.properties) //TODO: other stuff too
					});
					//TODO: check if there can be functions within these types
				}
			
			//create class for namespace itself
			currentPackage = toHaxePackage(null);
			declarations.push({
				pack: currentPackage,
				name: toHaxeType(ns.namespace),
				pos: null,
				kind: TDClass(),
				isExtern: true,
				meta: [{name: ":native", params: [valueToConstExpr(NATIVE_PACK + "." + ns.namespace)], pos: null}],
				fields: parseProperties(ns.properties)
					.concat(parseFunctions(ns.functions))
					.concat(parseEvents(ns.events)).map(makeStatic)
			});
		}

        return declarations;
    }

    function parseProperties(properties : Dynamic) : Array<Field> {
		return [for (field in Reflect.fields(properties)) {
			var prop : JsonProperty = Reflect.field(properties, field);
			var value = prop.value; //TODO: add this to FVar as expression
			if (prop.unsupported)
				continue;
			cast {
				name: field,
				doc: prop.description,
				access: value == null ? [APublic] : [APublic, AStatic, AInline],
				kind: value == null ? FVar(resolveType(prop)) : FVar(null, valueToConstExpr(value)),
			}
		}].map(escapeName);
	}

	function parseFunctions(functions : Array<JsonFunction>) : Array<Field> {
		return [for (func in functions) {
			if (func.unsupported)
				continue;
			var returnType = func.returns == null ? VOID : resolveType(func.returns);
			// if (func.async == "callback")
			// 	//FIXME: convert callback into Promise (which is what it actually is in Firefox),
			//  //maybe use a compiler flag or command line arg for that
			if (func.async == true) //schema does not define the type of promise
				returnType = TPath({ pack: ["js"], name: "Promise", params: [TPType(DYNAMIC)] }); //TODO: make fix list or something
			
			{
				name: func.name,
				doc: func.description,
				access: [APublic],
				pos: null,
				kind: FFun({
					args: func.parameters.map(function (p) return cast {
						name: p.name,
						opt: p.optional == true,
						type: resolveType(p)
					}),
					ret: returnType,
					expr: null
				})
			}
		}].map(escapeName);
	}

	function parseEvents(events : Array<JsonEvent>) : Array<Field> {
		return [for (e in events) {
			if (e.unsupported)
				continue;
			var callbackType = TPType(resolveType(e));
			var type = DYNAMIC;
			if (e.extraParameters == null) {
				type = TPath({pack: PACKAGE.concat(["events"]), name: "Event", params: [callbackType]});
			}
			else {
				if (e.extraParameters.length > 1)
					Sys.println("WARNING: More than one extra parameter for event " + e.name);
				
				var extraParam = e.extraParameters[0];
				var extraType = resolveType(extraParam);
				// if (extraParam.optional == true)
				// 	extraType = TOptional(extraType); //not allowed
				
				type = TPath({pack: PACKAGE.concat(["events"]), name: "ExtraEvent", params: [callbackType, TPType(extraType)]});
			}
			
			{
				name: e.name,
				doc: e.description,
				access: [APublic],
				pos: null,
				kind: FVar(type)
			}
		}].map(escapeName);
	}

    static var STRING = TPath({pack: [], name: "String"});
	static var BOOL = TPath({pack: [], name: "Bool"});
	static var INT = TPath({pack: [], name: "Int"});
	static var FLOAT = TPath({pack: [], name: "Float"});
	static var DYNAMIC = TPath({pack: [], name: "Dynamic"});
	static var VOID = TPath({pack: [], name: "Void"});
	static var NULL = TPath({pack: [], name: "Null", params: [TPType(DYNAMIC)]});

    function resolveType(decl : JsonTypeDecl) : ComplexType {
		switch (decl.type) {
			case "string": return STRING;
			case "boolean": return BOOL; 
			case "integer": return INT;
			case "number": return FLOAT;
			case "null": return NULL;
			case "array": return TPath({
					pack: [], name: "Array",
					params: [TPType(resolveType(decl.items))]
				});
			case "object":
				if (decl.properties == null)
					return DYNAMIC;
				
				var props = parseProperties(decl.properties);
				return TAnonymous(props);
			case "function":
				if (decl.parameters == null)
					return DYNAMIC;

				return TFunction(decl.parameters.map(function (p) {
						var type = resolveType(p);
						return p.optional == true ? TOptional(type) : type;
					}),
					decl.returns == null ? VOID : resolveType(decl.returns));
		}
		if (decl._ref == null) {
			if ((decl.choices == null || decl.choices.length > 2))
				return DYNAMIC;
			
			return TPath({
				pack: ["haxe", "ds"],
				name: "Either",
				params: decl.choices.map(function (choice) return TPType(resolveType(choice)))
			});
		}
		//try pack._ref
		var p = toHaxePackage(currentPackage.join("."));
		var name = toHaxeType(decl._ref);
		var candidate = knownTypes.get(p.join(".") + "." + name);
		if (candidate == null) {
			//try _ref itself as the full path
			var split = decl._ref.split(".");
			p = toHaxePackage(split.slice(0, split.length - 1).join("."));
			name = toHaxeType(split[split.length-1]);
			candidate = knownTypes.get(p.join(".") + "." + name);
		}
		
		if (candidate != null)
			return TPath({pack: p, name: name});
		else
			return DYNAMIC;
	}


    function toHaxeType(name : String)
		return name.charAt(0).toUpperCase() + name.substr(1);

	function toHaxePackage(namespace : String)
		if (namespace == null)
			return PACKAGE;
		else if (namespace.startsWith(PACKAGE.join(".") + "."))
			return namespace.toLowerCase().split(".");
		else
			return PACKAGE.concat(namespace.toLowerCase().split("."));
}