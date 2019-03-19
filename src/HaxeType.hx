
typedef HaxeType = {
    name : String,
    pack : Array<String>,
    ?doc : String,
}

typedef HaxeMemberType = {
    > HaxeType,
    // functions : Array<HaxeFunction>,
    // members : Array<HaxeMember>
}

typedef HaxeEnum = {
    > HaxeType,
    // values : Array<HaxeMember>
}

typedef HaxeTypedef = {
    > HaxeMemberType,
    
}

/** An actual class is only used for the top namespace **/
typedef HaxeClass = {
    > HaxeMemberType,
    native : String,

}