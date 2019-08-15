import json.types.*;
import haxe.macro.Expr;
import TypeHelper.*;

using StringTools;
using ArrayTools;

typedef DocumentedTypeDefinition = {
	> TypeDefinition,
	?doc : String
}

enum Platform {
	Chrome;
	Firefox;
}

class TypeGenerator {
    var namespaces : Iterable<JsonNamespace>;
    var knownTypes = new Map<String, Bool>();
    var currentPackage : Array<String>;
    var currentNamespace : Array<String>;

	var platform : Platform;
    public static var CHROME_PACKAGE = ["chrome"];
	static inline var CHROME_NATIVE_PACK = "chrome";
	public static var FIREFOX_PACKAGE = ["browser"];
	static inline var FIREFOX_NATIVE_PACK = "browser";

    public function new(schemas : Array<JsonNamespace>, predefinedTypes : Array<String>, platform : Platform) {
		this.platform = platform;

        this.namespaces = joinNamespaces(schemas);
        //mark namespaces as known
        for (ns in namespaces) {
			if (ns.types != null)
				for (type in ns.types)
					if (type.id != null)
						knownTypes.set(toHaxePackage(ns.namespace).join(".") + "." + toHaxeType(type.id), true);
		}
        for (type in predefinedTypes)
            knownTypes.set(type, true);
    }

	inline function getPackage() : Array<String>
		return switch (platform) {
			case Chrome: CHROME_PACKAGE;
			case Firefox: FIREFOX_PACKAGE;
		}
	inline function getNativePackage() : String
		return switch (platform) {
			case Chrome: CHROME_NATIVE_PACK;
			case Firefox: FIREFOX_NATIVE_PACK;
		}

    public function generate() : Array<DocumentedTypeDefinition> {
        var declarations : Array<DocumentedTypeDefinition> = [];
		
		for (ns in namespaces) {
			if (ns.types != null)
				for (type in ns.types) {
					currentPackage = toHaxePackage(ns.namespace);
                    currentNamespace = currentPackage;
					var parsedType = parseType(type);
					if (parsedType != null)
						declarations.push(parsedType);
				}
			
			//create class for namespace itself
			var split = ns.namespace.split(".");
			if (split.length > 1)
				currentPackage = toHaxePackage(split.allExceptLast().join("."));
			else
				currentPackage = toHaxePackage(null);
			currentNamespace = toHaxePackage(currentPackage.concat([split.last()]).join("."));

			declarations.push({
				pack: currentPackage,
				name: toHaxeType(split.last()),
				pos: null,
				kind: TDClass(),
				isExtern: true,
				meta: [{name: ":native", params: [valueToConstExpr(getNativePackage() + "." + ns.namespace)], pos: null}],
				fields: parseProperties(ns.properties)
					.concat(parseFunctions(ns.functions))
					.concat(parseEvents(ns.events)).map(makeStatic),
				doc: addPermissionsToDoc(ns.description, ns.permissions)
			});
		}

        return declarations;
    }

	function parseType(type : JsonType) : DocumentedTypeDefinition {
		if (type.enum_ != null) {
			return convertEnum(type);
		}
		else if (type.id != null) {
			return {
				pack: currentPackage,
				name: toHaxeType(type.id),
				pos: null,
				kind: type.choices == null ? TDStructure : TDAlias(resolveType(type)),
				fields: parseProperties(type.properties)
					.concat(parseFunctions(type.functions))
					.concat(parseEvents(type.events)),
				doc: addPermissionsToDoc(type.description, type.permissions)
			};
		}
		return null;
	}

    function parseProperties(properties : Dynamic) : Array<Field> {
		if (properties == null)
			return [];
		return [for (field in Reflect.fields(properties)) {
			var prop : JsonProperty = Reflect.field(properties, field);
			var value = prop.value;
			if (prop.unsupported)
				continue;
			cast {
				name: field,
				doc: addPermissionsToDoc(prop.description, prop.permissions),
				access: value == null ? [APublic] : [APublic, AStatic, AInline],
				kind: value == null ? FVar(resolveType(prop)) : FVar(null, valueToConstExpr(value)),
				meta: prop.optional == true ? [{name: ":optional", pos: null}] : null
			}
		}].map(escapeName);
	}

	function parseFunctions(functions : Array<JsonFunction>) : Array<Field> {
		if (functions == null)
			return [];
		return [for (func in functions) {
			if (func.unsupported)
				continue;
			var returnType = func.returns == null ? VOID : resolveType(func.returns);

            switch (func.async) {
                case Callback:
					//the Firefox api doc for some reason specifies callbacks,
					//although they actually are Promises, so this gets fixed here
                    #if (!chrome)
                    //assume last parameter is the callback
                    var callback = func.parameters.last();
                    func.parameters = func.parameters.allExceptLast();
					
                    var promiseType = VOID;
					if (callback.parameters != null) {
						if (callback.parameters.length > 1) {//more than one becomes Promise of Array
							var paramTypes = callback.parameters.map(resolveType);
							var paramType = paramTypes[0];
							for (t in paramTypes) //if all params have same type, use that one, otherwise Dynamic
								if (!paramType.equals(t)) {
									paramType = DYNAMIC;
									break;
								}

							promiseType = TPath({
								pack: [], name: "Array",
								params: [TPType(paramType)]
							});
						}
						else if (callback.parameters.length == 1)
							promiseType = resolveType(callback.parameters[0]);
					}
					
                    returnType = TPath({ pack: ["js"], name: "Promise", params: [TPType(promiseType)] });
					#end
                case True: //schema does not define the type of promise
                    returnType = TPath({ pack: ["js"], name: "Promise", params: [TPType(DYNAMIC)] }); //TODO: make fix list or something
                default:
            }

			{
				name: func.name,
				doc: addPermissionsToDoc(func.description, func.permissions),
				access: [APublic],
				pos: null,
				kind: FFun({
					args: func.parameters == null ? [] : func.parameters.map(function (p) return cast {
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
		if (events == null)
			return [];
		return [for (e in events) {
			if (e.unsupported)
				continue;
			var callbackType = TPType(resolveType(e));
			var type = DYNAMIC;
			if (e.extraParameters == null || e.extraParameters.length == 0) {
				type = TPath({pack: ["internal"], name: "Event", params: [callbackType]});
			}
			else {
				var extraTypes = e.extraParameters.map(resolveType).map(TPType);
				var pack = ["internal"];
				if (e.extraParameters.length > 2)
					Sys.println("WARNING: Too many extra parameter for event " + currentNamespace.join(".") + "." + e.name);

				if (e.extraParameters.length >= 2) {
					type = TPath({pack: pack, name: "ExtraEvent2", params: [callbackType, extraTypes[0], extraTypes[1]]});
				}
				else if (e.extraParameters.length == 1) {					
					type = TPath({pack: pack, name: "ExtraEvent", params: [callbackType, extraTypes[0]]});
				}
			}
			
			{
				name: e.name,
				doc: addPermissionsToDoc(e.description, e.permissions),
				access: [APublic],
				pos: null,
				kind: FVar(type)
			}
		}].map(escapeName);
	}

    /** Converts an enumerated type to a `@:enum abstract` **/
	function convertEnum(type : JsonType) : DocumentedTypeDefinition {
		return {
			pack: currentPackage,
			name: toHaxeType(type.id),
            meta: [{name: ":enum", pos: null}],
			pos: null,
			kind: TDAbstract(resolveType(type)),
			fields: type.enum_ == null ? [] : type.enum_.map(enumValueToField).map(escapeName),
			doc: addPermissionsToDoc(type.description, type.permissions)
		}
		return null;
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
			case String: return STRING;
			case Boolean: return BOOL; 
			case Integer: return INT;
			case Number: return FLOAT;
			case Null: return NULL;
			case Array: return TPath({
					pack: [], name: "Array",
					params: [TPType(resolveType(decl.items))]
				});
			case Object:
				if (decl.properties == null || decl.properties.length == 0)
					return DYNAMIC;
				
				var props = parseProperties(decl.properties);
				return TAnonymous(props);
			case Function:
				if (decl.parameters == null)
					return DYNAMIC;

				return TFunction(decl.parameters.map(function (p) {
						var type = resolveType(p);
						return p.optional == true ? TOptional(type) : type;
					}),
					decl.returns == null ? VOID : resolveType(decl.returns));
            case Any:
                return DYNAMIC;
            default:
		}
		if (decl.choices != null && decl.choices.length != 0) {
			if (decl.choices.length == 1)
				return resolveType(decl.choices[0]);
			
			//build nested EitherType
			var either = TPath({
				pack: ["haxe", "extern"],
				name: "EitherType",
				params: decl.choices.slice(0, 2).map(resolveType).map(TPType)
			});
			for (i in 2...decl.choices.length) {
				var c = decl.choices[i];
				either = TPath({
					pack: ["haxe", "extern"],
					name: "EitherType",
					params: [TPType(resolveType(c)), TPType(either)]
				});
			}
			return either;
		}
		else if (decl._ref == null)
			return DYNAMIC;
		//try pack._ref
		var p = toHaxePackage(currentNamespace.join("."));
		var name = toHaxeType(decl._ref);
		var candidate = knownTypes.get(p.join(".") + "." + name);
		if (candidate == null) {
			//try _ref itself as the full path
			var split = decl._ref.split(".");
			p = toHaxePackage(split.allExceptLast().join("."));
			name = toHaxeType(split.last());
			candidate = knownTypes.get(p.join(".") + "." + name);
		}
		
		if (candidate != null) {
			return TPath({pack: p, name: name});
		}
		else {
			Sys.println('WARNING: Type not found in package $currentNamespace $decl');
			return DYNAMIC;
		}
			
	}


    function toHaxeType(name : String)
		return name.charAt(0).toUpperCase() + name.substr(1);

	function toHaxePackage(namespace : String)
		if (namespace == null)
			return getPackage();
		else if (namespace == getPackage().join("."))
			return getPackage();
		else if (namespace.startsWith(getPackage().join(".") + "."))
			return namespace.toLowerCase().split(".");
		else
			return getPackage().concat(namespace.toLowerCase().split("."));
}