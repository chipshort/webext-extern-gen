
import haxe.macro.Expr;
import TypeGenerator.DocumentedTypeDefinition;
using Tuple.TupleTools;

using Lambda;
using ArrayTools;

class WrapperGenerator {

    static function main() {
        Sys.println("Parsing json files...");
        var chromeSchemas = SchemaHelper.loadSchemas(SchemaHelper.CHROME_FOLDER);
        var firefoxSchemas = SchemaHelper.loadSchemas(SchemaHelper.FIREFOX_FOLDER);

        var predefined = TypeHelper.collectPredefined();

        Sys.println("Generating externs...");
        var chromeDecls = new TypeGenerator(chromeSchemas, predefined, Chrome).generate();
        var firefoxDecls = new TypeGenerator(firefoxSchemas, predefined, Firefox).generate();
        chromeDecls.sort(compareTD);
        firefoxDecls.sort(compareTD);

        Sys.println("Comparing externs...");
        //compare generated types
        for (cDecl in chromeDecls) {
            var fDecl = binarySearch(firefoxDecls, cDecl, compareTD);
            if (fDecl != null) { //found matching declaration
                //TODO: I do not think this works like this
                var combinedDecl = Reflect.copy(fDecl);
                combinedDecl.pack = combinedDecl.pack.slice(1);
                combinedDecl.pack.insert(0, "extension");

                trace(cDecl.pack + cDecl.name);
                trace(fDecl.pack + fDecl.name);
                for (cField in cDecl.fields) {
                    var fField = fDecl.fields.find(function (f) return f.name == cField.name);
                    var combined = combineFields(cField, fField);
                    if (combined == null)
                        continue;
                    
                    trace(combined.name);
                    // //fields do not match
                    // var fullCField = '${cDecl.pack.join(".")}.${cDecl.name}.${cField.name}';
                    // var fullFField = '${fDecl.pack.join(".")}.${fDecl.name}.${fField.name}';
                    // Sys.println('WARNING: $fullCField does not match $fullFField');

                }
            }
        }

        //TODO: finish wrapper generator
    }

    static function combineFields(f1 : Field, f2 : Field) : Field {
        if (f1 == null || f2 == null)
            return null;

        switch ([f1.kind, f2.kind]) {
            case [FVar(t1, v1), FVar(t2, v2)]:
                if (equalsCT(t1, t2))
                    return f2;
            case [FFun(f1), FFun(f2)]:
                if (equalsFun(f1, f2))
                    return f2; //TODO: wrap Promise functions
            default:
        }

        return null;
    }

    static function equalsFun(f1 : Function, f2 : Function) : Bool {
        return false;
    }

    static function equalsCT(ct1 : ComplexType, ct2 : ComplexType) : Bool {
        switch ([ct1, ct2]) {
            case [TPath(p1), TPath(p2)]:
                //TODO: make special case for Promise and Callback
                var pack1 = normalizePack(p1.pack);
                var pack2 = normalizePack(p2.pack);

                var ct1 = typeParamToComplexType(TPType(p1));

                if ((pack1 == "js" && p1.name == "Promise" && equalsTP(p1.params[0], TPType(p2))
                    || pack2 == "js" && p2.name == "Promise") && true) {
                    return true;

                if (pack1 == pack2 && p1.name == p2.name && p1.sub == p2.sub
                    && p1.params.zipWith(p2.params)
                        .map(equalsTP.tuplify()).fold(function (b1, b2) return b1 && b2, true))
                    return true;
            case [TFunction(args1, ret1), TFunction(args2, ret2)]:
                var argsEqual = args1.zipWith(args2)
                    .map(equalsCT.tuplify()).fold(function (b1, b2) return b1 && b2, true);
                var retEquals = equalsCT(ret1, ret2);
            case [TAnonymous(fields1), TAnonymous(fields2)]:
            default:
        }
        return false;
    }

    static function equalsTP(tp1 : TypeParam, tp2 : TypeParam) : Bool {
        return switch ([tp1, tp2]) {
            case [TPType(t1), TPType(t2)]: equalsCT(t1, t2);
            default: false;
        }
    }

    static function typeParamToComplexType(tp : TypeParam) : ComplexType
        return switch (tp) {
            case TPType(t): t;
            default: null;
        }

    static function normalizePack(pack : Array<String>) : String
        return pack[0] == TypeGenerator.CHROME_PACKAGE[0] || pack[0] == TypeGenerator.FIREFOX_PACKAGE[0]
            ? pack.slice(1).join(".")
            : pack.join(".");

    static function compareTD(t1 : DocumentedTypeDefinition, t2 : DocumentedTypeDefinition) {
        //Remove base package (chrome or browser)
        var pack1 = normalizePack(t1.pack);
        var pack2 = normalizePack(t2.pack);
        var path1 = pack1 + "." + t1.name;
        var path2 = pack2 + "." + t2.name;

        if (path1 < path2)
            return -1;
        if (path1 > path2)
            return 1;

        return 0;
    }

    static function binarySearch<T>(array : Array<T>, type : T, compare : T->T->Int) {
        var low = 0;
        var high = array.length - 1;
        while (low <= high) {
            var mid = Std.int((low + high) / 2);
            var midType = array[mid];
            var comp = compare(midType, type);
            if (comp == 0) //midType == type
                return midType;
            else if (comp == -1)
                low = mid + 1;
            else
                high = mid - 1;
        }
        return null;
    }
}