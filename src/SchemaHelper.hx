
import json.JsonFix;
import hx.files.File;
import hx.files.Dir;
import json.types.*;

using ArrayTools;
using StringTools;

class SchemaHelper {

    #if chrome
    static var SCHEMAS_FOLDER = Dir.of("chrome_schemas");
    #else
    static var SCHEMAS_FOLDER = Dir.of("firefox_schemas");
    #end

    public static function loadSchemas() : Array<JsonNamespace> {
        var files = [];
        SCHEMAS_FOLDER.walk(function (file) files.push(file), function (_) return true);
        var schemaFiles = files
            .filter(function (file) return file.path.filenameExt == "json")
            .map(parseFile)
            .foldl(ArrayTools.concat, []);

        return schemaFiles;
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