module Main exposing (..)

import DomId exposing (DomId(ControlsArea, VideoArea))
import Html exposing (Html)
import MediaPlayer
import Mouse
import Ports exposing (Area)
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
    ( { audio = MediaPlayer.empty
      , video = MediaPlayer.empty
      , drag = NoDrag
      , videoArea = emptyArea
      , controlsArea = emptyArea
      , windowSize = { width = 0, height = 0 }
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
                Drag _ _ _ ->
                    [ Mouse.moves DragMove
                    , Mouse.ups DragEnd
                    ]

                NoDrag ->
                    []
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
                Ports.AreaMeasurement id area ->
                    case id of
                        DomId.VideoArea ->
                            ( { model | videoArea = area }, Cmd.none )

                        DomId.ControlsArea ->
                            ( { model | controlsArea = area }, Cmd.none )

                        _ ->
                            let
                                _ =
                                    Debug.log "unexpected AreaMeasurement" id
                            in
                            ( model, Cmd.none )

        JsMessage (Err message) ->
            let
                _ =
                    Debug.log "incomingMessage error" message
            in
            ( model, Cmd.none )

        MetaData id metaData ->
            let
                newModel =
                    case id of
                        Audio ->
                            { model
                                | audio =
                                    MediaPlayer.updateMetaData
                                        metaData
                                        model.audio
                            }

                        Video ->
                            { model
                                | video =
                                    MediaPlayer.updateMetaData
                                        metaData
                                        model.video
                            }
            in
            ( newModel, Cmd.none )

        CurrentTime id currentTime ->
            let
                newModel =
                    case id of
                        Audio ->
                            { model
                                | audio =
                                    MediaPlayer.updateCurrentTime
                                        currentTime
                                        model.audio
                            }

                        Video ->
                            { model
                                | video =
                                    MediaPlayer.updateCurrentTime
                                        currentTime
                                        model.video
                            }
            in
            ( newModel, Cmd.none )

        Play id ->
            case id of
                Audio ->
                    ( { model | audio = MediaPlayer.play model.audio }
                    , Ports.send (Ports.Play DomId.Audio)
                    )

                Video ->
                    ( { model | video = MediaPlayer.play model.video }
                    , Ports.send (Ports.Play DomId.Video)
                    )

        Pause id ->
            case id of
                Audio ->
                    ( { model | audio = MediaPlayer.pause model.audio }
                    , Ports.send (Ports.Pause DomId.Audio)
                    )

                Video ->
                    ( { model | video = MediaPlayer.pause model.video }
                    , Ports.send (Ports.Pause DomId.Video)
                    )

        DragStart id position mousePosition ->
            drag model id position mousePosition

        DragMove mousePosition ->
            case model.drag of
                Drag id position _ ->
                    drag model id position mousePosition

                NoDrag ->
                    ( model, Cmd.none )

        DragEnd _ ->
            ( { model | drag = NoDrag }
            , Cmd.none
            )

        WindowSize size ->
            ( { model | windowSize = size }
            , Cmd.batch
                [ Ports.send (Ports.MeasureArea DomId.VideoArea)
                , Ports.send (Ports.MeasureArea DomId.ControlsArea)
                ]
            )


drag :
    Model
    -> MediaPlayerId
    -> DragBar
    -> Mouse.Position
    -> ( Model, Cmd msg )
drag model id dragBar mousePosition =
    let
        offset =
            toFloat mousePosition.x
                - (model.controlsArea.x + dragBar.x)

        duration =
            case id of
                Audio ->
                    model.audio.duration

                Video ->
                    model.video.duration

        time =
            clamp 0
                duration
                ((offset / dragBar.width) * duration)

        outgoingMessage =
            case id of
                Audio ->
                    Ports.Seek DomId.Audio time

                Video ->
                    Ports.Seek DomId.Video time

        newDrag =
            Drag id dragBar mousePosition

        newModel =
            case id of
                Audio ->
                    { model
                        | audio = MediaPlayer.updateCurrentTime time model.audio
                        , drag = Drag id dragBar mousePosition
                    }

                Video ->
                    { model
                        | video = MediaPlayer.updateCurrentTime time model.video
                        , drag = Drag id dragBar mousePosition
                    }
    in
    ( newModel, Ports.send outgoingMessage )
