module Types exposing (..)

import Time exposing (Time)
import Window


type alias Model =
    { windowSize : Window.Size
    , videoDuration : Time
    , audioDuration : Time
    }


type Msg
    = NoOp
    | WindowSize Window.Size
    | VideoMetaData Time
    | AudioMetaData Time
