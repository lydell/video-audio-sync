module Types exposing (..)

import Html.Events.Custom exposing (MetaDataDetails, MouseButton, MouseDownDetails)
import MediaPlayer exposing (MediaPlayer)
import Mouse
import Ports exposing (Area, IncomingMessage)
import Time exposing (Time)
import Window


type alias Model =
    { audio : MediaPlayer
    , video : MediaPlayer
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
    | Looping { audioTime : Time, videoTime : Time, restarting : Bool }


type Drag
    = Drag DragDetails
    | NoDrag


type alias DragDetails =
    { id : MediaPlayerId
    , timeOffset : Float
    , dragBar : DragBar
    , lockState : LockState
    }


type alias DragBar =
    { x : Float
    , width : Float
    }


type alias JumpAction =
    { timeOffset : Time
    , label : String
    }


type Msg
    = NoOp
    | JsMessage (Result String IncomingMessage)
    | MetaData MediaPlayerId MetaDataDetails
    | CurrentTime MediaPlayerId Time
    | ExternalPlay MediaPlayerId
    | ExternalPause MediaPlayerId
    | Play MediaPlayerId MouseButton
    | Pause MediaPlayerId MouseButton
    | Jump MediaPlayerId Time MouseButton
    | DragStart MediaPlayerId DragBar MouseDownDetails
    | DragMove Mouse.Position
    | DragEnd Mouse.Position
    | GoNormal
    | GoLooping
    | WindowSize Window.Size
