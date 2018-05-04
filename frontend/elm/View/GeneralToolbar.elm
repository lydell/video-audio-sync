module View.GeneralToolbar exposing (generalToolbar)

import Data.Buttons as Buttons
import Data.KeyboardShortcuts exposing (KeyboardShortcutsWithState)
import Data.MediaPlayer as MediaPlayer
import Data.Model exposing (..)
import Data.Point as Point
import Html exposing (Html)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import ModelUtils
import View.ButtonGroup exposing (buttonGroup, emptyButton)
import View.Fontawesome exposing (Icon(Icon))
import View.Toolbar exposing (toolbar)


generalToolbar : Model -> KeyboardShortcutsWithState -> Html Msg
generalToolbar model keyboardShortcuts =
    let
        hasAudio =
            MediaPlayer.hasMedia model.audio

        hasVideo =
            MediaPlayer.hasMedia model.video

        ( audioCurrentTime, videoCurrentTime ) =
            ModelUtils.getCurrentTimes model

        potentialNewPoint =
            { audioTime = audioCurrentTime
            , videoTime = videoCurrentTime
            }

        selectedPoint =
            Point.getSelectedPoint potentialNewPoint model.points

        canAddPoint =
            Point.canAddPoint model.points potentialNewPoint

        warnings =
            Point.validate model.points

        numWarnings =
            List.length warnings
    in
    toolbar
        [ buttonGroup keyboardShortcuts
            [ { emptyButton
                | id = Buttons.toString Buttons.OpenPoints
                , icon = Icon "file-alt"
                , title = "Open points"
                , attributes =
                    [ onClick OpenPoints
                    , class
                        (if
                            (hasAudio || hasVideo)
                                || (model.editKeyboardShortcuts /= NotEditing)
                         then
                            ""
                         else
                            "is-animated"
                        )
                    ]
              }
            ]
        , buttonGroup keyboardShortcuts
            [ { emptyButton
                | id = Buttons.toString Buttons.Loop
                , icon = Icon "sync-alt"
                , title =
                    case model.loopState of
                        Normal ->
                            "Video and audio play normally. Click to loop."

                        Looping _ ->
                            "Video and audio loop around their current positions. Click to play normally."
                , pressed =
                    case model.loopState of
                        Normal ->
                            False

                        Looping _ ->
                            True
                , attributes =
                    [ onClick <|
                        case model.loopState of
                            Normal ->
                                GoLooping

                            Looping _ ->
                                GoNormal
                    , disabled (not (hasAudio && hasVideo))
                    ]
              }
            ]
        , buttonGroup keyboardShortcuts
            [ case selectedPoint of
                Just point ->
                    { emptyButton
                        | id = Buttons.toString Buttons.AddRemovePoint
                        , icon = Icon "minus"
                        , title = "Remove point"
                        , attributes =
                            [ onClick (RemovePoint point)
                            , disabled (not (hasAudio && hasVideo))
                            ]
                    }

                Nothing ->
                    { emptyButton
                        | id = Buttons.toString Buttons.AddRemovePoint
                        , icon = Icon "plus"
                        , title = "Add point"
                        , attributes =
                            [ onClick (AddPoint potentialNewPoint)
                            , disabled (not (hasAudio && hasVideo && canAddPoint))
                            ]
                    }
            , { emptyButton
                | id = Buttons.toString Buttons.Warnings
                , icon = Icon "exclamation-triangle "
                , title =
                    case numWarnings of
                        0 ->
                            "No warnings!"

                        1 ->
                            "1 warning"

                        _ ->
                            toString numWarnings ++ " warnings"
                , badge =
                    if numWarnings == 0 then
                        Nothing
                    else
                        Just <| toString numWarnings
                , attributes =
                    [ onClick OpenPointsWarningsModal
                    , disabled (numWarnings == 0)
                    ]
              }
            ]
        , buttonGroup keyboardShortcuts
            [ { emptyButton
                | id = Buttons.toString Buttons.Save
                , icon = Icon "save"
                , title = "Save points"
                , attributes =
                    [ onClick Save
                    , disabled (model.points == [])
                    ]
              }
            , { emptyButton
                | id = Buttons.toString Buttons.RemoveAll
                , icon = Icon "trash"
                , title = "Remove all points"
                , attributes =
                    [ onClick ConfirmRemoveAllPoints
                    , disabled (model.points == [])
                    ]
              }
            , { emptyButton
                | id = Buttons.toString Buttons.OpenMultiple
                , icon = Icon "copy"
                , title = "Open multiple files in one go"
                , attributes =
                    [ onClick OpenMultiple
                    , class
                        (if
                            (hasAudio || hasVideo)
                                || (model.editKeyboardShortcuts /= NotEditing)
                         then
                            ""
                         else
                            "is-animated"
                        )
                    ]
              }
            ]
        , buttonGroup keyboardShortcuts
            [ { emptyButton
                | id = Buttons.toString Buttons.ToggleShowKeyboardShortcuts
                , icon = Icon "keyboard"
                , title =
                    if model.showKeyboardShortcuts then
                        "Showing keyboard shortcuts. Click to hide."
                    else
                        "Not showing keyboard shortcuts. Click to show."
                , pressed = model.showKeyboardShortcuts
                , attributes =
                    [ onClick ToggleShowKeyboardShortcuts
                    ]
              }
            , { emptyButton
                | id = Buttons.toString Buttons.ToggleEditKeyboardShortcuts
                , icon = Icon "cog"
                , title =
                    if model.showKeyboardShortcuts then
                        "Editing keyboard shortcuts. Click to finish."
                    else
                        "Click to edit keyboard shortcuts."
                , pressed = model.editKeyboardShortcuts /= NotEditing
                , attributes =
                    [ onClick ToggleEditKeyboardShortcuts
                    ]
              }
            ]
        , buttonGroup keyboardShortcuts
            [ { emptyButton
                | id = Buttons.toString Buttons.HelpModal
                , icon = Icon "question-circle"
                , title = "Help"
                , pressed = model.helpModalOpen
                , attributes =
                    [ onClick OpenHelpModal
                    ]
              }
            ]
        ]
