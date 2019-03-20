package browser.extensiontypes;

typedef InjectDetails = {
    ?allFrames : Bool,
    ?code : String,
    ?file : String,
    ?frameId : Int,
    ?matchAboutBlank : Bool,
    ?runAt : RunAt
}