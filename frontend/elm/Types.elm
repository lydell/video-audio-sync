module Types exposing (..)

import Ports exposing (IncomingMessage)
import Time exposing (Time)
import Window


type alias Model =
    { windowSize : Window.Size
    , videoDuration : Time
    , audioDuration : Time
    }


type Msg
    = NoOp
    | JsMessage (Result String IncomingMessage)
    | WindowSize Window.Size
    | VideoMetaData Time
    | AudioMetaData Time
