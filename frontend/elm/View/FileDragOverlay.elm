module View.FileDragOverlay exposing (fileDragOverlay)

import Html exposing (Html, div, p, text)
import Html.Attributes exposing (class)
import View.Fontawesome exposing (Icon(CustomIcon), fontawesome)


fileDragOverlay : Html msg
fileDragOverlay =
    div [ class "FileDragOverlay" ]
        [ fontawesome (CustomIcon "copy" "fa-4x")
        , p []
            [ text "Drop video, audio and/or points" ]
        ]
