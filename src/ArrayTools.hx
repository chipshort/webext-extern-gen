
using ArrayTools;

class ArrayTools {
    public static inline function head<T>(a : Array<T>) : T
        return a[0];

    public static inline function tail<T>(a : Array<T>) : Array<T>
        return a.slice(1);

    public static inline function last<T>(a : Array<T>) : T
        return a[a.length-1];

    public static inline function allExceptLast<T>(a : Array<T>) : Array<T>
        return a.slice(0, a.length - 1);

    public static function foldl<T, U>(a : Array<T>, f : T->U->U, z : U) : U {
        while (a != null && a.length > 0) {
            z = f(a.head(), z);
            a = a.tail();
        }
        return z;
    }

    

    public static inline function distinct<T>(a : Array<T>) : Array<T> {
        var newArray = new Array<T>();
        for (x in a) {
            if (newArray.indexOf(x) < 0)
                newArray.push(x);
        }

        return newArray;
    }

    public static inline function concatArrays<T>(a : Array<T>, b : Array<T>) : Array<T>
        if (a == null)
			return b;
        else if (b == null)
            return a;
        else {
            return a.concat(b);
        }
            
}