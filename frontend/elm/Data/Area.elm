module Data.Area exposing (Area, decoder, empty)

import Json.Decode as Decode exposing (Decoder)


type alias Area =
    { width : Float
    , height : Float
    , x : Float
    , y : Float
    }


empty : Area
empty =
    { width = 0
    , height = 0
    , x = 0
    , y = 0
    }


decoder : Decoder Area
decoder =
    Decode.map4 Area
        (Decode.field "width" Decode.float)
        (Decode.field "height" Decode.float)
        (Decode.field "x" Decode.float)
        (Decode.field "y" Decode.float)
