module View.FileDragOverlay exposing (fileDragOverlay)

import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import View.Fontawesome exposing (Icon(Icon), fontawesome)


fileDragOverlay : Html msg
fileDragOverlay =
    div [ class "FileDragOverlay" ]
        [ div [ class "FileDragOverlay-icon" ]
            [ fontawesome (Icon "copy") ]
        , p []
            [ text "Drop video, audio and/or points" ]
        ]
