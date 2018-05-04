module ModelUtils exposing (..)

import Data.KeyboardShortcuts as KeyboardShortcuts exposing (KeyboardShortcutsWithState)
import Data.Model exposing (EditKeyboardShortcuts(NotEditing, WaitingForFirstKey, WaitingForSecondKey), LoopState(Looping, Normal), Model)
import Time exposing (Time)


loopRadius : Time
loopRadius =
    3 * Time.second


getCurrentTimes : Model -> ( Time, Time )
getCurrentTimes model =
    case model.loopState of
        Normal ->
            ( model.audio.currentTime
            , model.video.currentTime
            )

        Looping { audioTime, videoTime } ->
            ( audioTime
            , videoTime
            )


shownKeyboardShortcuts : Model -> KeyboardShortcutsWithState
shownKeyboardShortcuts model =
    if
        model.showKeyboardShortcuts
            || (model.editKeyboardShortcuts /= NotEditing)
    then
        let
            highlighted =
                case model.editKeyboardShortcuts of
                    NotEditing ->
                        []

                    WaitingForFirstKey { justChangedKeys } ->
                        List.map
                            (\key -> ( key, KeyboardShortcuts.JustChanged ))
                            justChangedKeys

                    WaitingForSecondKey { firstKey } ->
                        [ ( firstKey, KeyboardShortcuts.ToBeChanged ) ]
        in
        { keyboardShortcuts = model.keyboardShortcuts
        , highlighted = highlighted
        }
    else
        { keyboardShortcuts = KeyboardShortcuts.empty
        , highlighted = []
        }
