
using Tuple.TupleTools;

enum Tuple<T, U> {
    T(t : T, u : U);
}

class TupleTools {
    public static inline function fst<T, U>(t : Tuple<T, U>) : T
        return switch (t) {
            case T(t, u): return t;
        }
    public static inline function snd<T, U>(t : Tuple<T, U>) : U
        return switch (t) {
            case T(t, u): return u;
        }

    public static inline function tuplify<S, T, U>(f : S->T->U) : Tuple<S, T>->U
        return function (t) return f(t.fst(), t.snd());
}