
import json.JsonFix;
import json.types.JsonNamespace;
import hx.files.*;

using StringTools;
using ArrayTools;

class Main {
    #if chrome
    static var OUTPUT_FOLDER = Dir.of("chrome_output");
    #else
    static var OUTPUT_FOLDER = Dir.of("firefox_output");
    #end

    static function main() {
        Sys.println("Generating externs for " + #if chrome "Chrome" #else "Firefox" #end + ":");
        Sys.println("Parsing json files...");
        var schemaFiles = SchemaHelper.loadSchemas();
        
        var predefined = TypeHelper.collectPredefined();

        Sys.println("Generating externs...");
        var declarations = new TypeGenerator(schemaFiles, predefined).generate();

        //print out generated types
        OUTPUT_FOLDER.delete(true);
        Dir.of(TypeHelper.PREDEFINED_FOLDER.path.join("internal")).copyTo(OUTPUT_FOLDER.path.join("internal"));
        #if chrome
        Dir.of(TypeHelper.PREDEFINED_FOLDER.path.join("chrome")).copyTo(OUTPUT_FOLDER.path.join("chrome"));
        #else
        Dir.of(TypeHelper.PREDEFINED_FOLDER.path.join("browser")).copyTo(OUTPUT_FOLDER.path.join("browser"));
        #end
        Sys.println("Writing externs to " +  OUTPUT_FOLDER.path.toString() + "...");
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
}