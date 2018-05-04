module View.MediaPlayerToolbar exposing (mediaPlayerToolbar)

import Data.Buttons as Buttons exposing (JumpAction)
import Data.KeyboardShortcuts exposing (KeyboardShortcutsWithState)
import Data.MediaPlayer as MediaPlayer exposing (MediaPlayer, PlayState(Paused, Playing))
import Data.Model exposing (..)
import Data.Point exposing (Direction(Backward, Forward))
import Html exposing (Html, p, text)
import Html.Attributes exposing (class, disabled)
import Html.Custom exposing (none)
import Html.Events exposing (onClick)
import Html.Events.Custom exposing (onClickWithButton)
import Utils
import View.ButtonGroup exposing (ButtonDetails, ButtonLabel(LeftLabel, RightLabel), buttonGroup, emptyButton)
import View.Fontawesome exposing (Icon(CustomIcon, Icon))
import View.Toolbar exposing (toolbar)


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
