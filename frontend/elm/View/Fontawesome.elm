module View.Fontawesome exposing (Icon(..), fontawesome)

import Html exposing (Html, span)
import Html.Attributes exposing (attribute, class)
import View.Icons as Icons


type Icon
    = Icon String
    | CustomIcon String String


fontawesome : Icon -> Html msg
fontawesome icon =
    let
        ( namePart, extraClass ) =
            case icon of
                Icon name ->
                    ( name, "" )

                CustomIcon name extra ->
                    ( name, extra )
    in
    case namePart of
        "file-video" ->
            Icons.film

        "file-audio" ->
            Icons.volume2

        "file-alt" ->
            Icons.fileText

        "play" ->
            Icons.play

        "pause" ->
            Icons.pause

        "play-circle" ->
            Icons.playCircle

        "pause-circle" ->
            Icons.pauseCircle

        "backward" ->
            Icons.rewind

        "forward" ->
            Icons.fastForward

        "step-backward" ->
            Icons.skipBack

        "step-forward" ->
            Icons.skipForward

        "sync-alt" ->
            Icons.repeat

        "plus" ->
            Icons.plus

        "minus" ->
            Icons.minus

        "save" ->
            Icons.save

        "trash" ->
            Icons.trash2

        "copy" ->
            Icons.copy

        "cog" ->
            Icons.settings

        "question-circle" ->
            Icons.helpCircle

        "keyboard" ->
            Icons.command

        "exclamation-triangle " ->
            Icons.alertTriangle

        _ ->
            span
                [ attribute "aria-hidden" "true"
                , class ("fas fa-" ++ namePart ++ " " ++ extraClass)
                ]
                []
