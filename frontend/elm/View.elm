module View exposing (view)

import Data.Buttons as Buttons exposing (JumpAction)
import Data.DomId as DomId
import Data.KeyboardShortcuts as KeyboardShortcuts exposing (KeyboardShortcutsWithState)
import Data.MediaPlayer as MediaPlayer exposing (MediaPlayer, PlayState(Paused, Playing))
import Data.Model exposing (..)
import Data.Point as Point exposing (Direction(Backward, Forward))
import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class, classList, disabled)
import Html.Custom exposing (none)
import Html.Events exposing (onClick)
import Html.Events.Custom exposing (onClickWithButton, preventContextMenu)
import ModelUtils
import Utils
import View.ButtonGroup exposing (ButtonDetails, ButtonLabel(LeftLabel, RightLabel), buttonGroup, emptyButton)
import View.EditKeyboardShortcuts
import View.Fontawesome exposing (Icon(CustomIcon, Icon), fontawesome)
import View.Graphics
import View.Media
import View.Modals.ConfirmOpenPoints
import View.Modals.ConfirmRemoveAllPoints
import View.Modals.Errors
import View.Modals.Help
import View.Modals.PointsWarnings


view : Model -> Html Msg
view model =
    div [ class "Layout" ]
        [ div [ class "Layout-videoWrapper", DomId.toHtml DomId.VideoArea ] <|
            case View.EditKeyboardShortcuts.view model of
                Just content ->
                    [ content ]

                Nothing ->
                    View.Media.view model
        , viewControls model
        , viewModals model
        , if model.isDraggingFile then
            fileDragOverlay
          else
            none
        ]


viewControls : Model -> Html Msg
viewControls model =
    let
        shownKeyboardShortcuts =
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
                                List.map (\key -> ( key, KeyboardShortcuts.JustChanged )) justChangedKeys

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
    in
    div
        [ classList
            [ ( "Layout-controls", True )
            , ( "is-editKeyboardShortcuts", model.editKeyboardShortcuts /= NotEditing )
            ]
        , preventContextMenu
        ]
        [ mediaPlayerToolbar Video
            model.video
            model.loopState
            shownKeyboardShortcuts
            model.editKeyboardShortcuts
        , View.Graphics.view model
        , mediaPlayerToolbar Audio
            model.audio
            model.loopState
            shownKeyboardShortcuts
            model.editKeyboardShortcuts
        , generalToolbar model shownKeyboardShortcuts
        ]


mediaPlayerToolbar :
    MediaPlayerId
    -> MediaPlayer
    -> LoopState
    -> KeyboardShortcutsWithState
    -> EditKeyboardShortcuts
    -> Html Msg
mediaPlayerToolbar id mediaPlayer loopState keyboardShortcuts editKeyboardShortcuts =
    let
        hasMedia =
            MediaPlayer.hasMedia mediaPlayer

        backwardEnabled =
            hasMedia && mediaPlayer.currentTime > 0

        forwardEnabled =
            hasMedia && mediaPlayer.currentTime < mediaPlayer.duration

        ( name, icon ) =
            case id of
                Audio ->
                    ( "Audio", Icon "file-audio" )

                Video ->
                    ( "Video", Icon "file-video" )

        ( playPauseTitle, playPauseIcon ) =
            case ( mediaPlayer.playState, loopState ) of
                ( Playing, Normal ) ->
                    ( name ++ " is playing. Click to pause."
                    , Icon "pause"
                    )

                ( Playing, Looping _ ) ->
                    ( "Looping. Click to pause."
                    , CustomIcon "pause-circle" "fa-1.25"
                    )

                ( Paused, Normal ) ->
                    ( name ++ " is paused. Click to play."
                    , Icon "play"
                    )

                ( Paused, Looping _ ) ->
                    ( "Paused. Click to loop."
                    , CustomIcon "play-circle" "fa-1.25"
                    )
    in
    toolbar
        [ buttonGroup keyboardShortcuts
            [ { emptyButton
                | id = Buttons.toString (Buttons.OpenMedia id)
                , icon = icon
                , title = "Open " ++ String.toLower name
                , attributes =
                    [ onClick (OpenMedia id)
                    , class
                        (if hasMedia || editKeyboardShortcuts /= NotEditing then
                            ""
                         else
                            "is-animated"
                        )
                    ]
              }
            ]
        , buttonGroup keyboardShortcuts
            [ { emptyButton
                | id = Buttons.toString (Buttons.PlayPause id)
                , icon = playPauseIcon
                , title = playPauseTitle
                , pressed =
                    case mediaPlayer.playState of
                        Playing ->
                            True

                        Paused ->
                            False
                , attributes =
                    disabled (not hasMedia)
                        :: (onClickWithButton <|
                                case mediaPlayer.playState of
                                    Playing ->
                                        Pause id

                                    Paused ->
                                        Play id
                           )
              }
            ]
        , buttonGroup keyboardShortcuts <|
            List.map (buttonDetailsFromJumpAction id backwardEnabled) Buttons.jumpActionsBackward
        , buttonGroup keyboardShortcuts <|
            List.map (buttonDetailsFromJumpAction id forwardEnabled) Buttons.jumpActionsForward
        , buttonGroup keyboardShortcuts
            [ { emptyButton
                | id = Buttons.toString (Buttons.JumpByPoint id Backward)
                , icon = Icon "step-backward"
                , title = "Previous point"
                , attributes =
                    disabled (not backwardEnabled)
                        :: onClickWithButton (JumpByPoint id Backward)
              }
            , { emptyButton
                | id = Buttons.toString (Buttons.JumpByPoint id Forward)
                , icon = Icon "step-forward"
                , title = "Next point"
                , attributes =
                    disabled (not forwardEnabled)
                        :: onClickWithButton (JumpByPoint id Forward)
              }
            ]
        , if mediaPlayer.duration > 0 then
            p []
                [ text <|
                    Utils.formatDuration mediaPlayer.currentTime
                        ++ " / "
                        ++ Utils.formatDuration mediaPlayer.duration
                ]
          else
            none
        ]


buttonDetailsFromJumpAction :
    MediaPlayerId
    -> Bool
    -> JumpAction
    -> ButtonDetails Msg
buttonDetailsFromJumpAction id enabled jumpAction =
    let
        base =
            { emptyButton
                | attributes =
                    disabled (not enabled)
                        :: onClickWithButton (JumpByTime id jumpAction.timeOffset)
            }
    in
    if jumpAction.timeOffset < 0 then
        { base
            | id =
                Buttons.toString
                    (Buttons.JumpByTime id Backward jumpAction.timeOffset)
            , icon = Icon "backward"
            , title = "Jump backward: " ++ jumpAction.label
            , label = RightLabel jumpAction.label
        }
    else
        { base
            | id =
                Buttons.toString
                    (Buttons.JumpByTime id Forward jumpAction.timeOffset)
            , icon = Icon "forward"
            , title = "Jump forward: " ++ jumpAction.label
            , label = LeftLabel jumpAction.label
        }


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


toolbar : List (Html msg) -> Html msg
toolbar children =
    div [ class "Toolbar" ] children


fileDragOverlay : Html msg
fileDragOverlay =
    div [ class "FileDragOverlay" ]
        [ fontawesome (CustomIcon "copy" "fa-4x")
        , p []
            [ text "Drop video, audio and/or points" ]
        ]


viewModals : Model -> Html Msg
viewModals model =
    div []
        [ if model.pointsWarningsModalOpen then
            View.Modals.PointsWarnings.view ClosePointsWarningsModal model.points
          else
            none
        , if model.confirmRemoveAllPointsModalOpen then
            View.Modals.ConfirmRemoveAllPoints.view
                { cancel = CloseRemoveAllPoints
                , confirm = RemoveAllPoints
                }
          else
            none
        , case model.confirmOpenPoints of
            Just { name, points } ->
                View.Modals.ConfirmOpenPoints.view
                    { cancel = CloseOpenPoints
                    , confirm = OpenConfirmedPoints points
                    , name = name
                    }

            Nothing ->
                none
        , case model.errors of
            [] ->
                none

            errors ->
                View.Modals.Errors.view CloseErrorsModal (List.reverse errors)
        , if model.helpModalOpen then
            View.Modals.Help.view CloseHelpModal
          else
            none
        ]
