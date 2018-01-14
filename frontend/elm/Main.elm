module Main exposing (..)

import DomId exposing (DomId(IdControlsArea, IdVideoArea))
import Html exposing (Html)
import Mouse
import Ports exposing (Area, IncomingMessage(AreaMeasurement), OutgoingMessage(AudioSeek, JsAudioPlayState, JsVideoPlayState, MeasureArea, VideoSeek))
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
      , drag = NoDrag
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
    let
        mouseSubscriptions =
            case model.drag of
                NoDrag ->
                    []

                Drag _ _ _ ->
                    [ Mouse.moves DragMove
                    , Mouse.ups DragEnd
                    ]
    in
    Sub.batch <|
        [ Window.resizes WindowSize
        , Ports.subscribe JsMessage
        ]
            ++ mouseSubscriptions


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

        DragStart dragElement position mousePosition ->
            drag model dragElement position mousePosition

        DragMove mousePosition ->
            case model.drag of
                NoDrag ->
                    ( model, Cmd.none )

                Drag dragElement position _ ->
                    drag model dragElement position mousePosition

        DragEnd _ ->
            ( { model | drag = NoDrag }
            , Cmd.none
            )


drag :
    Model
    -> DragElement
    -> FooPosition
    -> Mouse.Position
    -> ( Model, Cmd msg )
drag model dragElement position mousePosition =
    let
        offset =
            toFloat mousePosition.x
                - (model.controlsArea.x + position.x)

        duration =
            case dragElement of
                Audio ->
                    model.audioDuration

                Video ->
                    model.videoDuration

        time =
            clamp 0
                duration
                ((offset / position.width) * duration)

        outgoingMessage =
            case dragElement of
                Audio ->
                    AudioSeek time

                Video ->
                    VideoSeek time

        newDrag =
            Drag dragElement position mousePosition

        newModel =
            case dragElement of
                Audio ->
                    { model
                        | drag = Drag dragElement position mousePosition
                        , audioCurrentTime = time
                    }

                Video ->
                    { model
                        | drag = Drag dragElement position mousePosition
                        , videoCurrentTime = time
                    }
    in
    ( newModel, Ports.send outgoingMessage )
