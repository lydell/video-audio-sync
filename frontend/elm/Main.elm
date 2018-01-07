module Main exposing (..)

import Html exposing (Html)
import Ports exposing (OutgoingMessage(JsPause, JsPlay, TestOut))
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
      , videoSize = { width = 0, height = 0 }
      , videoDuration = 0
      , audioDuration = 0
      , videoCurrentTime = 0
      , audioCurrentTime = 0
      , playing = False
      }
    , Cmd.batch
        [ Task.perform WindowSize Window.size
        , Ports.send (TestOut "Hello, JS!")
        ]
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Window.resizes WindowSize
        , Ports.subscribe JsMessage
        ]


view : Model -> Html Msg
view model =
    View.view model


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        JsMessage (Ok incomingMessage) ->
            let
                _ =
                    Debug.log "incomingMessage" incomingMessage
            in
            ( model, Cmd.none )

        JsMessage (Err message) ->
            let
                _ =
                    Debug.log "incomingMessage error" message
            in
            ( model, Cmd.none )

        WindowSize size ->
            ( { model | windowSize = size }, Cmd.none )

        VideoMetaData { duration, width, height } ->
            ( { model
                | videoDuration = duration
                , videoSize = { width = width, height = height }
              }
            , Cmd.none
            )

        AudioMetaData { duration } ->
            ( { model | audioDuration = duration }, Cmd.none )

        VideoCurrentTime currentTime ->
            ( { model | videoCurrentTime = currentTime }, Cmd.none )

        AudioCurrentTime currentTime ->
            ( { model | audioCurrentTime = currentTime }, Cmd.none )

        VideoPlayState playing ->
            ( { model | playing = playing }, Cmd.none )

        AudioPlayState playing ->
            ( { model | playing = playing }, Cmd.none )

        Play ->
            ( { model | playing = True }, Ports.send JsPlay )

        Pause ->
            ( { model | playing = False }, Ports.send JsPause )
