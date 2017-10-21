module Main exposing (..)

import Html
import Types exposing (..)
import View


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = View.view
        }


init : ( Model, Cmd Msg )
init =
    ( { videoUrl = "TODO" }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
