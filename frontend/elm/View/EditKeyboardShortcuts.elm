module View.EditKeyboardShortcuts exposing (view)

import Data.Buttons as Buttons
import Data.Model exposing (..)
import Html exposing (Html, button, div, kbd, p, text)
import Html.Attributes exposing (class, type_)
import Html.Custom exposing (none)
import Html.Events exposing (onClick)
import View.ButtonGroup exposing (formatKey)


view : Model -> Maybe (Html Msg)
view model =
    case model.editKeyboardShortcuts of
        NotEditing ->
            Nothing

        WaitingForFirstKey { unavailableKey } ->
            Just <|
                div [ class "MegaMessage MegaMessage--short" ]
                    [ case unavailableKey of
                        Just key ->
                            p [ class "MegaMessage-before" ]
                                [ kbd [] [ text (formatKey key) ]
                                , text " has no shortcut."
                                ]

                        Nothing ->
                            none
                    , p [] [ text "Press the keyboard shortcut you want to change." ]
                    , case model.undoKeyboardShortcuts of
                        Just _ ->
                            p [ class "MegaMessage-after" ]
                                [ text "All reset! ("
                                , button
                                    [ type_ "button"
                                    , class "LinkButton"
                                    , onClick UndoResetKeyboardShortcuts
                                    ]
                                    [ text "Undo" ]
                                , text ")"
                                ]

                        Nothing ->
                            if model.keyboardShortcuts == Buttons.defaultKeyboardShortCuts then
                                none
                            else
                                p [ class "MegaMessage-after" ]
                                    [ button
                                        [ type_ "button"
                                        , class "OutlineButton"
                                        , onClick ResetKeyboardShortcuts
                                        ]
                                        [ text "Reset all shortcuts" ]
                                    ]
                    ]

        WaitingForSecondKey { unavailableKey, firstKey } ->
            Just <|
                div [ class "MegaMessage MegaMessage--short" ] <|
                    case unavailableKey of
                        Just key ->
                            [ p [ class "MegaMessage-before" ]
                                [ kbd [] [ text (formatKey key) ]
                                , text <| " cannot be used."
                                ]
                            , p []
                                [ text "Press a new keyboard shortcut for:" ]
                            , p [ class "MegaMessage-after" ]
                                [ kbd [] [ text (formatKey firstKey) ] ]
                            ]

                        Nothing ->
                            [ p []
                                [ text "Now press a new keyboard shortcut for:" ]
                            , p [ class "MegaMessage-after" ]
                                [ kbd [] [ text (formatKey firstKey) ] ]
                            ]
