module Types exposing (..)

import Html.Events.Custom exposing (MetaDataDetails)
import MediaPlayer exposing (MediaPlayer)
import Mouse
import Ports exposing (Area, IncomingMessage)
import Time exposing (Time)
import Window


type alias Model =
    { audio : MediaPlayer
    , video : MediaPlayer
    , lockState : LockState
    , loopState : LoopState
    , drag : Drag
    , videoArea : Area
    , controlsArea : Area
    , windowSize : Window.Size
    }


type MediaPlayerId
    = Audio
    | Video


type LockState
    = Locked
    | Unlocked


type LoopState
    = Normal
    | Looping Time Time


type Drag
    = Drag DragDetails
    | NoDrag


type alias DragDetails =
    { id : MediaPlayerId
    , timeOffset : Float
    , dragBar : DragBar
    }


type alias DragBar =
    { x : Float
    , width : Float
    }


type Msg
    = NoOp
    | JsMessage (Result String IncomingMessage)
    | MetaData MediaPlayerId MetaDataDetails
    | CurrentTime MediaPlayerId Time
    | Play MediaPlayerId
    | Pause MediaPlayerId
    | DragStart MediaPlayerId DragBar Mouse.Position
    | DragMove Mouse.Position
    | DragEnd Mouse.Position
    | Lock
    | Unlock
    | GoNormal
    | GoLooping
    | WindowSize Window.Size
