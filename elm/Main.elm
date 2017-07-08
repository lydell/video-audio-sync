module Main exposing (..)

import Html exposing (p, text)


main : Program Never () msg
main =
    Html.program
        { init = ( (), Cmd.none )
        , update = \msg model -> ( model, Cmd.none )
        , subscriptions = \model -> Sub.none
        , view = \model -> p [] [ text "Hello, World!" ]
        }
