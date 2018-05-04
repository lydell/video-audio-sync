module View.Toolbar exposing (toolbar)

import Html exposing (Html, div)
import Html.Attributes exposing (class)


toolbar : List (Html msg) -> Html msg
toolbar children =
    div [ class "Toolbar" ] children
