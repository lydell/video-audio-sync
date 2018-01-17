module Main exposing (..)

import DomId exposing (DomId(ControlsArea, VideoArea))
import Html exposing (Html)
import MediaPlayer exposing (MediaPlayer)
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
        , view = View.view
        }


init : ( Model, Cmd Msg )
init =
    ( { audio = MediaPlayer.empty
      , video = MediaPlayer.empty
      , lockState = Unlocked
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
                Drag _ _ _ _ ->
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

        MetaData id details ->
            ( updateMediaPlayer (MediaPlayer.updateMetaData details) id model
            , Cmd.none
            )

        CurrentTime id currentTime ->
            ( updateMediaPlayer
                (MediaPlayer.updateCurrentTime currentTime)
                id
                model
            , Cmd.none
            )

        Play id ->
            case model.lockState of
                Locked ->
                    ( { model
                        | audio = MediaPlayer.play model.audio
                        , video = MediaPlayer.play model.video
                      }
                    , Cmd.batch
                        [ Ports.send (Ports.Play DomId.Audio)
                        , Ports.send (Ports.Play DomId.Video)
                        ]
                    )

                Unlocked ->
                    ( updateMediaPlayer MediaPlayer.play id model
                    , Ports.send (Ports.Play (domIdFromMediaPlayerId id))
                    )

        Pause id ->
            case model.lockState of
                Locked ->
                    ( { model
                        | audio = MediaPlayer.pause model.audio
                        , video = MediaPlayer.pause model.video
                      }
                    , Cmd.batch
                        [ Ports.send (Ports.Pause DomId.Audio)
                        , Ports.send (Ports.Pause DomId.Video)
                        ]
                    )

                Unlocked ->
                    ( updateMediaPlayer MediaPlayer.pause id model
                    , Ports.send (Ports.Pause (domIdFromMediaPlayerId id))
                    )

        DragStart id position mousePosition ->
            let
                offset =
                    case id of
                        Audio ->
                            model.audio.currentTime - model.video.currentTime

                        Video ->
                            model.video.currentTime - model.audio.currentTime
            in
            drag model id offset position mousePosition

        DragMove mousePosition ->
            case model.drag of
                Drag id offset position _ ->
                    drag model id offset position mousePosition

                NoDrag ->
                    ( model, Cmd.none )

        DragEnd _ ->
            ( { model | drag = NoDrag }
            , Cmd.none
            )

        Lock ->
            ( { model | lockState = Locked }
            , Cmd.none
            )

        Unlock ->
            ( { model | lockState = Unlocked }
            , Cmd.none
            )

        WindowSize size ->
            ( { model | windowSize = size }
            , Cmd.batch
                [ Ports.send (Ports.MeasureArea DomId.VideoArea)
                , Ports.send (Ports.MeasureArea DomId.ControlsArea)
                ]
            )


updateMediaPlayer : (MediaPlayer -> MediaPlayer) -> MediaPlayerId -> Model -> Model
updateMediaPlayer update id model =
    case id of
        Audio ->
            { model | audio = update model.audio }

        Video ->
            { model | video = update model.video }


domIdFromMediaPlayerId : MediaPlayerId -> DomId
domIdFromMediaPlayerId id =
    case id of
        Audio ->
            DomId.Audio

        Video ->
            DomId.Video


drag :
    Model
    -> MediaPlayerId
    -> Float
    -> DragBar
    -> Mouse.Position
    -> ( Model, Cmd msg )
drag model id offset dragBar mousePosition =
    let
        dragged =
            toFloat mousePosition.x - (model.controlsArea.x + dragBar.x)

        clampTime duration time =
            clamp 0 duration time

        calculateTime duration =
            clampTime duration ((dragged / dragBar.width) * duration)

        newDrag =
            Drag id offset dragBar mousePosition
    in
    case model.lockState of
        Locked ->
            let
                ( audioTime, videoTime ) =
                    case id of
                        Audio ->
                            let
                                oldTime =
                                    model.audio.currentTime

                                newTime =
                                    calculateTime model.audio.duration
                            in
                            ( newTime
                            , clampTime model.video.duration (newTime - offset)
                            )

                        Video ->
                            let
                                oldTime =
                                    model.video.currentTime

                                newTime =
                                    calculateTime model.video.duration
                            in
                            ( clampTime model.audio.duration (newTime - offset)
                            , newTime
                            )

                newModel =
                    { model
                        | audio = MediaPlayer.updateCurrentTime audioTime model.audio
                        , video = MediaPlayer.updateCurrentTime videoTime model.video
                    }
            in
            ( { newModel | drag = newDrag }
            , Cmd.batch
                [ Ports.send (Ports.Seek DomId.Audio audioTime)
                , Ports.send (Ports.Seek DomId.Video videoTime)
                ]
            )

        Unlocked ->
            let
                duration =
                    case id of
                        Audio ->
                            model.audio.duration

                        Video ->
                            model.video.duration

                time =
                    calculateTime duration

                newModel =
                    updateMediaPlayer (MediaPlayer.updateCurrentTime time) id model
            in
            ( { newModel | drag = newDrag }
            , Ports.send (Ports.Seek (domIdFromMediaPlayerId id) time)
            )
