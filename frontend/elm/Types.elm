module Types exposing (..)

import Data.Area exposing (Area)
import Data.File exposing (ErroredFileDetails, InvalidFileDetails, OpenedFileDetails)
import Data.KeyboardShortcuts exposing (KeyboardShortcuts)
import Data.MediaPlayer exposing (MediaPlayer)
import Data.Point exposing (Direction, Point)
import Html.Events.Custom exposing (MetaDataDetails, MouseButton, MouseDownDetails)
import Mouse
import Ports exposing (IncomingMessage)
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
    , keyboardShortcuts : KeyboardShortcuts
    , undoKeyboardShortcuts : Maybe KeyboardShortcuts
    , showKeyboardShortcuts : Bool
    , editKeyboardShortcuts : EditKeyboardShortcuts
    , helpModalOpen : Bool
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


type Error
    = InvalidFileError InvalidFileDetails
    | ErroredFileError ErroredFileDetails
    | MediaError ErroredFileDetails
    | InvalidPointsError InvalidPointsDetails


type alias InvalidPointsDetails =
    { name : String
    , message : String
    }


type alias KeyboardShortcutsWithState =
    { keyboardShortcuts : KeyboardShortcuts
    , highlighted : List ( String, KeyboardShortcutState )
    }


type KeyboardShortcutState
    = Regular
    | ToBeChanged
    | JustChanged


type EditKeyboardShortcuts
    = NotEditing
    | WaitingForFirstKey { unavailableKey : Maybe String, justChangedKeys : List String }
    | WaitingForSecondKey { unavailableKey : Maybe String, firstKey : String }


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
    | ToggleShowKeyboardShortcuts
    | ToggleEditKeyboardShortcuts
    | ResetKeyboardShortcuts
    | UndoResetKeyboardShortcuts
    | OpenHelpModal
    | CloseHelpModal
    | WindowSize Window.Size
