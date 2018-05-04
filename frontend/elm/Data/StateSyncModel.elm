module Data.StateSyncModel exposing (StateSyncModel, empty, encode)

import Data.KeyboardShortcuts as KeyboardShortcuts exposing (KeyboardShortcuts)
import Json.Encode as Encode


type alias StateSyncModel =
    { keyboardShortcuts : KeyboardShortcuts
    , editingKeyboardShortcuts : Bool
    , warnOnClose : Maybe String
    }


empty : StateSyncModel
empty =
    { keyboardShortcuts = KeyboardShortcuts.empty
    , editingKeyboardShortcuts = False
    , warnOnClose = Nothing
    }


encode : StateSyncModel -> Encode.Value
encode model =
    Encode.object
        [ ( "keyboardShortcuts"
          , KeyboardShortcuts.encode model.keyboardShortcuts
          )
        , ( "editingKeyboardShortcuts"
          , Encode.bool model.editingKeyboardShortcuts
          )
        , ( "warnOnClose"
          , case model.warnOnClose of
                Just message ->
                    Encode.string message

                Nothing ->
                    Encode.null
          )
        ]
