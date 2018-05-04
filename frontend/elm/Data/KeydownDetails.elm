module Data.KeydownDetails exposing (KeydownDetails, keydownDetailsDecoder)

import Json.Decode as Decode exposing (Decoder)


type alias KeydownDetails =
    { key : String
    , altKey : Bool
    , ctrlKey : Bool
    , metaKey : Bool
    , shiftKey : Bool
    }


keydownDetailsDecoder : Decoder KeydownDetails
keydownDetailsDecoder =
    Decode.map5 KeydownDetails
        (Decode.field "key" Decode.string)
        (Decode.field "altKey" Decode.bool)
        (Decode.field "ctrlKey" Decode.bool)
        (Decode.field "metaKey" Decode.bool)
        (Decode.field "shiftKey" Decode.bool)
