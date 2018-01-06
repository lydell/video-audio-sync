module Types exposing (..)

import Ports exposing (IncomingMessage)
import Time exposing (Time)
import Window


type alias Model =
    { windowSize : Window.Size
    , videoSize : { width : Float, height : Float }
    , videoDuration : Time
    , audioDuration : Time
    , playing : Bool
    }


type alias VideoMetaDataDetails =
    { duration : Time
    , width : Float
    , height : Float
    }


type alias AudioMetaDataDetails =
    { duration : Time
    }


type Msg
    = NoOp
    | JsMessage (Result String IncomingMessage)
    | WindowSize Window.Size
    | VideoMetaData VideoMetaDataDetails
    | AudioMetaData AudioMetaDataDetails
    | Play
    | Pause
