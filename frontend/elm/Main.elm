module Main exposing (..)

import Element
import Html exposing (Html)
import StyleSheet
import Types exposing (..)
import View


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
    ( { videoDuration = 0
      , audioDuration = 0
      }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


view : Model -> Html Msg
view model =
    Element.viewport StyleSheet.styleSheet <|
        View.view model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        VideoMetaData duration ->
            ( { model | videoDuration = duration }, Cmd.none )

        AudioMetaData duration ->
            ( { model | audioDuration = duration }, Cmd.none )
