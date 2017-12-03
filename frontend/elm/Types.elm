module Types exposing (..)

import Time exposing (Time)


type alias Model =
    { videoDuration : Time
    , audioDuration : Time
    }


type Msg
    = NoOp
    | VideoMetaData Time
    | AudioMetaData Time
