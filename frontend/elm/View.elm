module View exposing (view)

import Html exposing (Html, p, text)
import Types exposing (..)


view : Model -> Html Msg
view model =
    p [] [ text "Hello, World!" ]
