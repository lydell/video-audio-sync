module Data.Area exposing (Area, areaDecoder, emptyArea)

import Json.Decode as Decode exposing (Decoder)


type alias Area =
    { width : Float
    , height : Float
    , x : Float
    , y : Float
    }


emptyArea : Area
emptyArea =
    { width = 0
    , height = 0
    , x = 0
    , y = 0
    }


areaDecoder : Decoder Area
areaDecoder =
    Decode.map4 Area
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
