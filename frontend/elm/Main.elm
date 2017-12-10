module Main exposing (..)

import Html exposing (Html)
import Task
import Types exposing (..)
import View
import Window


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : ( Model, Cmd Msg )
init =
    ( { windowSize = { width = 0, height = 0 }
      , videoDuration = 0
      , audioDuration = 0
      }
    , Task.perform WindowSize Window.size
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Window.resizes WindowSize


view : Model -> Html Msg
view model =
    View.view model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        WindowSize size ->
            ( { model | windowSize = size }, Cmd.none )

        VideoMetaData duration ->
            ( { model | videoDuration = duration }, Cmd.none )

        AudioMetaData duration ->
            ( { model | audioDuration = duration }, Cmd.none )
