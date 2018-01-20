module Main exposing (..)

import DomId exposing (DomId(GraphicsArea, VideoArea))
import Html exposing (Html)
import Html.Events.Custom exposing (MouseButton(Left, Right))
import MediaPlayer exposing (MediaPlayer)
import Mouse
import Ports exposing (Area)
import Task
import Time exposing (Time)
import Types exposing (..)
import View
import Window


loopRadius : Time
loopRadius =
    3 * Time.second


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
      , loopState = Normal
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
                Drag _ ->
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

                        DomId.GraphicsArea ->
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
            let
                ( cmd, newLoopState ) =
                    case model.loopState of
                        Normal ->
                            ( Cmd.none, model.loopState )

                        Looping { audioTime, videoTime, restarting } ->
                            let
                                startMovement =
                                    min loopRadius (min audioTime videoTime)

                                endMovement =
                                    min loopRadius <|
                                        min
                                            (model.audio.duration - audioTime)
                                            (model.video.duration - videoTime)

                                audioStartTime =
                                    audioTime - startMovement

                                videoStartTime =
                                    videoTime - startMovement

                                audioEndTime =
                                    audioTime + endMovement

                                videoEndTime =
                                    videoTime + endMovement

                                shouldRestart =
                                    (model.audio.currentTime >= audioEndTime)
                                        || (model.video.currentTime >= videoEndTime)
                            in
                            if shouldRestart && not restarting then
                                ( Ports.send
                                    (Ports.RestartLoop
                                        { audioTime = audioStartTime
                                        , videoTime = videoStartTime
                                        }
                                    )
                                , Looping
                                    { audioTime = audioTime
                                    , videoTime = videoTime
                                    , restarting = True
                                    }
                                )
                            else
                                ( Cmd.none
                                , Looping
                                    { audioTime = audioTime
                                    , videoTime = videoTime
                                    , restarting = shouldRestart
                                    }
                                )
            in
            ( updateMediaPlayer
                (MediaPlayer.updateCurrentTime currentTime)
                id
                { model | loopState = newLoopState }
            , cmd
            )

        ExternalPlay id ->
            play Unlocked id model

        ExternalPause id ->
            pause Unlocked id model

        Play id mouseButton ->
            play (lockStateFromMouseButton mouseButton) id model

        Pause id mouseButton ->
            pause (lockStateFromMouseButton mouseButton) id model

        DragStart id dragBar mouseDownDetails ->
            let
                timeOffset =
                    case id of
                        Audio ->
                            model.audio.currentTime - model.video.currentTime

                        Video ->
                            model.video.currentTime - model.audio.currentTime

                dragDetails =
                    { id = id
                    , timeOffset = timeOffset
                    , dragBar = dragBar
                    , lockState = lockStateFromMouseButton mouseDownDetails.button
                    }

                newModel =
                    { model | drag = Drag dragDetails }
            in
            drag newModel dragDetails mouseDownDetails.position

        DragMove mousePosition ->
            case model.drag of
                Drag dragDetails ->
                    drag model dragDetails mousePosition

                NoDrag ->
                    ( model, Cmd.none )

        DragEnd _ ->
            ( { model | drag = NoDrag }
            , Cmd.none
            )

        GoNormal ->
            ( { model | loopState = Normal }
            , Cmd.none
            )

        GoLooping ->
            ( { model
                | loopState =
                    Looping
                        { audioTime = model.audio.currentTime
                        , videoTime = model.video.currentTime
                        , restarting = False
                        }
              }
            , Cmd.none
            )

        WindowSize size ->
            ( { model | windowSize = size }
            , Cmd.batch
                [ Ports.send (Ports.MeasureArea DomId.VideoArea)
                , Ports.send (Ports.MeasureArea DomId.GraphicsArea)
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


lockStateFromMouseButton : MouseButton -> LockState
lockStateFromMouseButton mouseButton =
    case mouseButton of
        Left ->
            Unlocked

        Right ->
            Locked


updateLockAware :
    LockState
    -> Model
    -> MediaPlayerId
    -> (MediaPlayer -> MediaPlayer)
    -> (DomId -> Ports.OutgoingMessage)
    -> ( Model, Cmd Msg )
updateLockAware lockState model id update msg =
    case lockState of
        Locked ->
            ( { model
                | audio = update model.audio
                , video = update model.video
              }
            , Cmd.batch
                [ Ports.send (msg DomId.Audio)
                , Ports.send (msg DomId.Video)
                ]
            )

        Unlocked ->
            ( updateMediaPlayer update id model
            , Ports.send (msg (domIdFromMediaPlayerId id))
            )


play : LockState -> MediaPlayerId -> Model -> ( Model, Cmd Msg )
play lockState id model =
    pausePlayHelper MediaPlayer.play Ports.Play lockState id model


pause : LockState -> MediaPlayerId -> Model -> ( Model, Cmd Msg )
pause lockState id model =
    let
        result =
            pausePlayHelper MediaPlayer.pause Ports.Pause lockState id model
    in
    case model.loopState of
        Normal ->
            result

        Looping { restarting } ->
            -- When restarting a loop, the audio and video are temporarily
            -- paused. Skip updating the state in this case to avoid the
            -- play/pause buttons flashing between paused and playing.
            if restarting then
                ( model, Cmd.none )
            else
                result


pausePlayHelper :
    (MediaPlayer -> MediaPlayer)
    -> (DomId -> Ports.OutgoingMessage)
    -> LockState
    -> MediaPlayerId
    -> Model
    -> ( Model, Cmd Msg )
pausePlayHelper update msg lockState id model =
    let
        newLockState =
            case model.loopState of
                Normal ->
                    lockState

                Looping _ ->
                    Locked
    in
    updateLockAware newLockState model id update msg


drag :
    Model
    -> DragDetails
    -> Mouse.Position
    -> ( Model, Cmd msg )
drag model { id, timeOffset, dragBar, lockState } mousePosition =
    let
        dragged =
            toFloat mousePosition.x - (model.controlsArea.x + dragBar.x)

        calculateTime duration =
            (dragged / dragBar.width) * duration

        update =
            MediaPlayer.updateCurrentTime

        msg =
            Ports.Seek
    in
    case lockState of
        Locked ->
            let
                ( audioTime, videoTime ) =
                    case id of
                        Audio ->
                            let
                                newTime =
                                    calculateTime model.audio.duration
                            in
                            ( newTime
                            , newTime - timeOffset
                            )

                        Video ->
                            let
                                newTime =
                                    calculateTime model.video.duration
                            in
                            ( newTime - timeOffset
                            , newTime
                            )

                newModel =
                    { model
                        | audio = update audioTime model.audio
                        , video = update videoTime model.video
                    }

                newLoopState =
                    case model.loopState of
                        Normal ->
                            Normal

                        Looping _ ->
                            Looping
                                { audioTime = newModel.audio.currentTime
                                , videoTime = newModel.video.currentTime
                                , restarting = False
                                }
            in
            ( { newModel | loopState = newLoopState }
            , Cmd.batch
                [ Ports.send (msg DomId.Audio audioTime)
                , Ports.send (msg DomId.Video videoTime)
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
            in
            ( updateMediaPlayer (update time) id model
            , Ports.send (msg (domIdFromMediaPlayerId id) time)
            )
