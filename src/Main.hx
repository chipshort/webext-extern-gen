
import haxe.Json;
import json.JsonFix;
import json.types.JsonNamespace;
import hx.files.*;

using StringTools;
using ArrayTools;

class Main {
    #if chrome
    static var OUTPUT_FOLDER = Dir.of("chrome_output");
    static var SCHEMAS_FOLDER = Dir.of("chrome_schemas");
    #else
    static var OUTPUT_FOLDER = Dir.of("firefox_output");
    static var SCHEMAS_FOLDER = Dir.of("firefox_schemas");
    #end
    static var PREDEFINED_FOLDER = Dir.of("predefined");

    static function main() {
        var files = [];
        SCHEMAS_FOLDER.walk(function (file) files.push(file), function (_) return true);
        var parsed = files
            .filter(function (file) return file.path.filenameExt == "json")
            .map(parseFile)
            .foldl(ArrayTools.concatArrays, []);
        
        var namespaces = joinNamespaces(parsed);
        
        //collect predefined types
        var predefined = [];
        PREDEFINED_FOLDER.walk(function (file) {
            var dotPath = pathToDotPath(file.path);
            predefined.push(dotPath);
        }, function (dir) return true);		

        var declarations = new TypeGenerator(namespaces, predefined).generate();

        //print out generated types
        OUTPUT_FOLDER.delete(true);
        #if chrome
        Dir.of(PREDEFINED_FOLDER.path.join("chrome")).copyTo(OUTPUT_FOLDER.path.join("chrome"));
        #else
        Dir.of(PREDEFINED_FOLDER.path.join("browser")).copyTo(OUTPUT_FOLDER.path.join("browser"));
        #end
        var printer = new haxe.macro.Printer("\t");
        for (decl in declarations) {
            var folder = OUTPUT_FOLDER.path.join(decl.pack.join(OUTPUT_FOLDER.path.dirSep));
            var file = File.of(folder.join(decl.name + ".hx"));
            folder.toDir().create();
            var output = file.openOutput(REPLACE);

            output.writeString("//AUTOMATICALLY GENERATED\n");
            //print package
            output.writeString('package ${decl.pack.join(".")};\n');
            if (decl.doc != null)
                output.writeString("/** " + decl.doc + " **/");
            output.writeString("\n");
            output.writeString(printer.printTypeDefinition(decl, false));
            output.close();
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

    /** Joins all namespaces with the same `namespace` together **/
    static function joinNamespaces(namespaces : Array<JsonNamespace>) : Array<JsonNamespace> {
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
            var events = pack.map(function (ns) return ns.events).foldl(ArrayTools.concatArrays, []);
            var types = pack.map(function (ns) return ns.types).foldl(ArrayTools.concatArrays, []);
            var funcs = pack.map(function (ns) return ns.functions).foldl(ArrayTools.concatArrays, []);
            var props = pack.map(function (ns) return ns.properties).foldl(merge, {});
            var permissions = pack.map(function (ns) return ns.permissions).foldl(ArrayTools.concatArrays, []).distinct();
            
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

    static function parseFile(file : File) {
        var content = file.readAsString();
        //need to convert to "\r\n", because of some quirk in TJSON
        content = content.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "\r\n");
        
        try {
            var j = tjson.TJSON.parse(content, file.path.toString());
            var json : Array<JsonNamespace> = JsonFix.fixSpecialChars(j);
            if (!Std.is(json, Array))
                return [];
            return json;
        } catch (e : Dynamic) {
            trace("Could not parse " + file + " " + e);
        }
        return [];
    }
}