module View.FileDragOverlay exposing (fileDragOverlay)

import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import View.Icons as Icons


fileDragOverlay : Html msg
fileDragOverlay =
    div [ class "FileDragOverlay" ]
        [ div [ class "FileDragOverlay-icon" ]
            [ Icons.copy ]
        , p []
            [ text "Drop video, audio and/or points" ]
        ]
