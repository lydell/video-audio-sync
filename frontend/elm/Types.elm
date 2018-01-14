module Types exposing (..)

import Mouse
import Ports exposing (Area, IncomingMessage)
import Time exposing (Time)
import Window


type alias Model =
    { windowSize : Window.Size
    , drag : Drag
    , videoSize : { width : Float, height : Float }
    , videoDuration : Time
    , audioDuration : Time
    , videoCurrentTime : Time
    , audioCurrentTime : Time
    , videoPlaying : Bool
    , audioPlaying : Bool
    , videoArea : Area
    , controlsArea : Area
    }


type Drag
    = NoDrag
    | Drag DragElement FooPosition Mouse.Position


type DragElement
    = Audio
    | Video


type alias FooPosition =
    { x : Float
    , width : Float
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
    | VideoCurrentTime Time
    | AudioCurrentTime Time
    | VideoPlayState Bool
    | AudioPlayState Bool
    | DragStart DragElement FooPosition Mouse.Position
    | DragMove Mouse.Position
    | DragEnd Mouse.Position
