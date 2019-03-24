
import json.JsonFix;
import hx.files.File;
import hx.files.Dir;
import json.types.*;

using ArrayTools;
using StringTools;

class SchemaHelper {

    public static var CHROME_FOLDER = Dir.of("chrome_schemas");
    public static var FIREFOX_FOLDER = Dir.of("firefox_schemas");

    public static inline function loadSchemas(folder : Dir) : Array<JsonNamespace> {
        return folder.findFiles("**/*.json")
            .map(parseFile)
            .foldl(ArrayTools.concat, []);
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