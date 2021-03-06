module Data.Model exposing (..)

import Data.Area as Area exposing (Area)
import Data.Error as Error exposing (Error)
import Data.KeyboardShortcuts as KeyboardShortcuts exposing (KeyboardShortcuts)
import Data.MediaPlayer as MediaPlayer exposing (MediaPlayer)
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


empty : Model
empty =
    { audio = MediaPlayer.empty
    , video = MediaPlayer.empty
    , loopState = Normal
    , drag = NoDrag
    , videoArea = Area.empty
    , controlsArea = Area.empty
    , windowSize = { width = 0, height = 0 }
    , points = []
    , pointsWarningsModalOpen = False
    , isDraggingFile = False
    , confirmRemoveAllPointsModalOpen = False
    , confirmOpenPoints = Nothing
    , errors = []
    , keyboardShortcuts = KeyboardShortcuts.empty
    , undoKeyboardShortcuts = Nothing
    , showKeyboardShortcuts = False
    , editKeyboardShortcuts = NotEditing
    , helpModalOpen = False
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


type EditKeyboardShortcuts
    = NotEditing
    | WaitingForFirstKey { unavailableKey : Maybe String, justChangedKeys : List String }
    | WaitingForSecondKey { unavailableKey : Maybe String, firstKey : String }


type Msg
    = JsMessage (Result String IncomingMessage)
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
    | CloseErrorsModal
    | OpenPointsWarningsModal
    | ClosePointsWarningsModal
    | ToggleShowKeyboardShortcuts
    | ToggleEditKeyboardShortcuts
    | ResetKeyboardShortcuts
    | UndoResetKeyboardShortcuts
    | OpenHelpModal
    | CloseHelpModal
    | WindowSize Window.Size
