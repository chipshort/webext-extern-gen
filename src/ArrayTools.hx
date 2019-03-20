

class ArrayTools {
    public static function last<T>(a : Array<T>) : T
        return a[a.length-1];

    public static function allExceptLast<T>(a : Array<T>) : Array<T>
        return a.slice(0, a.length - 1);
}