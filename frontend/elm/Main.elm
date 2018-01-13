module Main exposing (..)

import DomId exposing (DomId(IdControlsArea, IdVideoArea))
import Html exposing (Html)
import Ports exposing (Area, IncomingMessage(AreaMeasurement), OutgoingMessage(JsAudioPlayState, JsVideoPlayState, MeasureArea))
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
      , videoPlaying = False
      , audioPlaying = False
      , videoArea = emptyArea
      , controlsArea = emptyArea
      }
    , Task.perform WindowSize Window.size
    )


emptyArea : Area
emptyArea =
    { width = 0
    , height = 0
    , x = 0
    , y = 0
    }


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
            case incomingMessage of
                AreaMeasurement id area ->
                    case id of
                        IdVideoArea ->
                            ( { model | videoArea = area }, Cmd.none )

                        IdControlsArea ->
                            ( { model | controlsArea = area }, Cmd.none )

        JsMessage (Err message) ->
            let
                _ =
                    Debug.log "incomingMessage error" message
            in
            ( model, Cmd.none )

        WindowSize size ->
            ( { model | windowSize = size }
            , Cmd.batch
                [ Ports.send (MeasureArea IdVideoArea)
                , Ports.send (MeasureArea IdControlsArea)
                ]
            )

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
            ( { model | videoPlaying = playing }
            , Ports.send (JsVideoPlayState playing)
            )

        AudioPlayState playing ->
            ( { model | audioPlaying = playing }
            , Ports.send
                (JsAudioPlayState playing)
            )
