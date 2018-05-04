module Data.StateSyncModel exposing (StateSyncModel, encodeStateSyncModel)

import Data.KeyboardShortcuts exposing (KeyboardShortcuts, encodeKeyboardShortcuts)
import Json.Encode as Encode


type alias StateSyncModel =
    { keyboardShortcuts : KeyboardShortcuts
    , editingKeyboardShortcuts : Bool
    , warnOnClose : Maybe String
    }


encodeStateSyncModel : StateSyncModel -> Encode.Value
encodeStateSyncModel model =
    Encode.object
        [ ( "keyboardShortcuts"
          , encodeKeyboardShortcuts model.keyboardShortcuts
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
