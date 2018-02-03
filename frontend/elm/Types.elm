module Types exposing (..)

import Html.Events.Custom exposing (MetaDataDetails, MouseButton, MouseDownDetails)
import MediaPlayer exposing (MediaPlayer)
import Mouse
import Ports exposing (Area, ErroredFileDetails, IncomingMessage, InvalidFileDetails, OpenedFileDetails)
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
    , points : List Point
    , pointsWarningsModalOpen : Bool
    , isDraggingFile : Bool
    , confirmRemoveAllPointsModalOpen : Bool
    , confirmOpenPoints : Maybe { name : String, points : List Point }
    , errors : List Error
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


type alias Point =
    { audioTime : Time
    , videoTime : Time
    }


type alias JumpAction =
    { timeOffset : Time
    , label : String
    }


type Direction
    = Forward
    | Backward


type Error
    = InvalidFileError InvalidFileDetails
    | ErroredFileError ErroredFileDetails
    | MediaError ErroredFileDetails
    | InvalidPointsError InvalidPointsDetails


type alias InvalidPointsDetails =
    { name : String
    , message : String
    }


type Msg
    = NoOp
    | JsMessage (Result String IncomingMessage)
    | MediaErrorMsg MediaPlayerId
    | MetaData MediaPlayerId MetaDataDetails
    | CurrentTime MediaPlayerId Time
    | ExternalPlay MediaPlayerId
    | ExternalPause MediaPlayerId
    | Play MediaPlayerId MouseButton
    | Pause MediaPlayerId MouseButton
    | JumpByTime MediaPlayerId Time MouseButton
    | JumpByPoint MediaPlayerId Direction MouseButton
    | DragStart MediaPlayerId DragBar MouseDownDetails
    | DragMove Mouse.Position
    | DragEnd Mouse.Position
    | GoNormal
    | GoLooping
    | AddPoint Point
    | RemovePoint Point
    | RemoveAllPoints
    | ConfirmRemoveAllPoints
    | CloseRemoveAllPoints
    | Save
    | OpenMedia MediaPlayerId
    | OpenPoints
    | OpenConfirmedPoints (List Point)
    | CloseOpenPoints
    | OpenMultiple
    | CloseErrorModal
    | OpenPointsWarningsModal
    | ClosePointsWarningsModal
    | WindowSize Window.Size
