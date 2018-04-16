module Main exposing (..)

import Buttons
import Dict
import DomId exposing (DomId(GraphicsArea, VideoArea))
import Html exposing (Html)
import Html.Events.Custom exposing (MouseButton(Left, Right))
import Json.Decode as Decode
import Json.Encode as Encode
import MediaPlayer exposing (MediaPlayer)
import Mouse
import Points
import Ports exposing (Area)
import Task
import Time exposing (Time)
import Types exposing (..)
import Utils
import View
import Window


loopRadius : Time
loopRadius =
    3 * Time.second


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , update = updateWithCmds
        , subscriptions = subscriptions
        , view = View.view
        }


type alias Flags =
    { audio : Maybe String
    , video : Maybe String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        empty =
            MediaPlayer.empty

        withLocalName maybeName =
            case maybeName of
                Just name ->
                    { empty | name = name, url = Just ("/" ++ name) }

                Nothing ->
                    empty
    in
    ( { audio = withLocalName flags.audio
      , video = withLocalName flags.video
      , loopState = Normal
      , drag = NoDrag
      , videoArea = emptyArea
      , controlsArea = emptyArea
      , windowSize = { width = 0, height = 0 }
      , points = []
      , pointsWarningsModalOpen = False
      , isDraggingFile = False
      , confirmRemoveAllPointsModalOpen = False
      , confirmOpenPoints = Nothing
      , errors = []
      , keyboardShortcuts = Buttons.defaultKeyboardShortCuts
      , showKeyboardShortcuts = False
      , editKeyboardShortcuts = NotEditing
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


updateWithCmds : Msg -> Model -> ( Model, Cmd Msg )
updateWithCmds msg model =
    let
        ( newModel, cmd ) =
            update msg model

        warnOnCloseMessage =
            case newModel.points of
                [] ->
                    Nothing

                _ ->
                    Just "Make sure you have saved your points before leaving. They will be lost otherwise."
    in
    ( newModel
    , Cmd.batch
        [ cmd
        , Ports.send (Ports.WarnOnClose warnOnCloseMessage)
        ]
    )


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

                Ports.OpenedFile { name, fileType, content } ->
                    let
                        empty =
                            MediaPlayer.empty

                        newModel =
                            case fileType of
                                Ports.AudioFile ->
                                    { model
                                        | audio =
                                            { empty
                                                | name = name
                                                , url = Just content
                                            }
                                    }

                                Ports.VideoFile ->
                                    { model
                                        | video =
                                            { empty
                                                | name = name
                                                , url = Just content
                                            }
                                    }

                                Ports.JsonFile ->
                                    let
                                        decoded =
                                            Decode.decodeString
                                                Points.decoder
                                                content
                                    in
                                    case decoded of
                                        Ok points ->
                                            case model.points of
                                                [] ->
                                                    { model | points = points }

                                                _ ->
                                                    { model
                                                        | confirmOpenPoints =
                                                            Just
                                                                { name = name
                                                                , points = points
                                                                }
                                                    }

                                        Err message ->
                                            addError
                                                (InvalidPointsError
                                                    { name = name
                                                    , message = message
                                                    }
                                                )
                                                model
                    in
                    ( newModel, Cmd.none )

                Ports.InvalidFile details ->
                    ( addError (InvalidFileError details) model, Cmd.none )

                Ports.ErroredFile details ->
                    ( addError (ErroredFileError details) model, Cmd.none )

                Ports.DragEnter ->
                    ( { model | isDraggingFile = True }, Cmd.none )

                Ports.DragLeave ->
                    ( { model | isDraggingFile = False }, Cmd.none )

                Ports.Keydown { key, altKey, ctrlKey, metaKey } ->
                    let
                        mouseButton =
                            if altKey || ctrlKey || metaKey then
                                Right
                            else
                                Left

                        buttonId =
                            Dict.get key model.keyboardShortcuts
                    in
                    case model.editKeyboardShortcuts of
                        NotEditing ->
                            ( model
                            , case buttonId of
                                Just id ->
                                    Ports.send (Ports.ClickButton id mouseButton)

                                Nothing ->
                                    Cmd.none
                            )

                        WaitingForFirstKey ->
                            ( { model
                                | editKeyboardShortcuts =
                                    case buttonId of
                                        Just _ ->
                                            WaitingForSecondKey key

                                        _ ->
                                            model.editKeyboardShortcuts
                              }
                            , Cmd.none
                            )

                        WaitingForSecondKey firstKey ->
                            ( { model
                                | editKeyboardShortcuts = WaitingForFirstKey
                                , keyboardShortcuts =
                                    updateKeyboardShortcuts
                                        firstKey
                                        key
                                        model.keyboardShortcuts
                              }
                            , Cmd.none
                            )

        JsMessage (Err message) ->
            let
                _ =
                    Debug.log "incomingMessage error" message
            in
            ( model, Cmd.none )

        MediaErrorMsg id ->
            let
                name =
                    case id of
                        Audio ->
                            { name = model.audio.name
                            , fileType = Ports.AudioFile
                            }

                        Video ->
                            { name = model.video.name
                            , fileType = Ports.VideoFile
                            }

                newModel =
                    model
                        |> updateMediaPlayer
                            (always MediaPlayer.empty)
                            id
                        |> addError (MediaError name)
            in
            ( newModel, Cmd.none )

        MetaData id details ->
            ( updateMediaPlayer (MediaPlayer.updateMetaData details) id model
            , Cmd.none
            )

        CurrentTime id currentTime ->
            updateCurrentTime id currentTime model

        ExternalPlay id ->
            play Unlocked id model

        ExternalPause id ->
            case model.loopState of
                Normal ->
                    pause Unlocked id model

                Looping { restarting } ->
                    -- When restarting a loop, the audio and video are
                    -- temporarily paused. Skip updating the state in this case
                    -- to avoid the play/pause buttons flashing between paused
                    -- and playing.
                    if restarting then
                        ( model, Cmd.none )
                    else
                        pause Unlocked id model

        Play id mouseButton ->
            play (lockStateFromMouseButton mouseButton) id model

        Pause id mouseButton ->
            pause (lockStateFromMouseButton mouseButton) id model

        JumpByTime id timeOffset mouseButton ->
            jumpByTime (lockStateFromMouseButton mouseButton) id timeOffset model

        JumpByPoint id direction mouseButton ->
            jumpByPoint (lockStateFromMouseButton mouseButton) id direction model

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

        AddPoint point ->
            ( { model | points = point :: model.points }, Cmd.none )

        RemovePoint point ->
            let
                newPoints =
                    List.filter ((/=) point) model.points
            in
            ( { model | points = newPoints }, Cmd.none )

        RemoveAllPoints ->
            ( { model | points = [], confirmRemoveAllPointsModalOpen = False }
            , Cmd.none
            )

        ConfirmRemoveAllPoints ->
            ( { model | confirmRemoveAllPointsModalOpen = True }, Cmd.none )

        CloseRemoveAllPoints ->
            ( { model | confirmRemoveAllPointsModalOpen = False }, Cmd.none )

        Save ->
            let
                encoded =
                    Points.encode model.points

                content =
                    model.points
                        |> Points.encode
                        |> Encode.encode 0
            in
            ( model
            , Ports.send
                (Ports.SaveFile
                    { filename = pointsSaveFilename model.audio.name
                    , content = content
                    , mimeType = "application/json"
                    }
                )
            )

        OpenMedia id ->
            let
                fileType =
                    case id of
                        Audio ->
                            Ports.AudioFile

                        Video ->
                            Ports.VideoFile
            in
            ( model
            , Ports.send (Ports.OpenFile fileType)
            )

        OpenPoints ->
            ( model
            , Ports.send (Ports.OpenFile Ports.JsonFile)
            )

        OpenConfirmedPoints points ->
            ( { model | points = points, confirmOpenPoints = Nothing }
            , Cmd.none
            )

        CloseOpenPoints ->
            ( { model | confirmOpenPoints = Nothing }, Cmd.none )

        OpenMultiple ->
            ( model
            , Ports.send Ports.OpenMultipleFiles
            )

        CloseErrorModal ->
            ( { model | errors = [] }, Cmd.none )

        OpenPointsWarningsModal ->
            ( { model | pointsWarningsModalOpen = True }, Cmd.none )

        ClosePointsWarningsModal ->
            ( { model | pointsWarningsModalOpen = False }, Cmd.none )

        ToggleShowKeyboardShortcuts ->
            ( { model | showKeyboardShortcuts = not model.showKeyboardShortcuts }
            , Cmd.none
            )

        ToggleEditKeyboardShortcuts ->
            ( { model
                | editKeyboardShortcuts =
                    if model.editKeyboardShortcuts == NotEditing then
                        WaitingForFirstKey
                    else
                        NotEditing
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
    -> (MediaPlayer -> DomId -> Ports.OutgoingMessage)
    -> ( Model, Cmd Msg )
updateLockAware lockState model id update msg =
    case lockState of
        Locked ->
            let
                newModel =
                    { model
                        | audio = update model.audio
                        , video = update model.video
                    }
            in
            ( newModel
            , Cmd.batch
                [ Ports.send (msg newModel.audio DomId.Audio)
                , Ports.send (msg newModel.video DomId.Video)
                ]
            )

        Unlocked ->
            let
                newModel =
                    updateMediaPlayer update id model

                mediaPlayer =
                    case id of
                        Audio ->
                            newModel.audio

                        Video ->
                            newModel.video
            in
            ( newModel
            , Ports.send (msg mediaPlayer (domIdFromMediaPlayerId id))
            )


play : LockState -> MediaPlayerId -> Model -> ( Model, Cmd Msg )
play lockState id model =
    pausePlayHelper MediaPlayer.play Ports.Play lockState id model


pause : LockState -> MediaPlayerId -> Model -> ( Model, Cmd Msg )
pause lockState id model =
    pausePlayHelper MediaPlayer.pause Ports.Pause lockState id model


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
    updateLockAware newLockState model id update (always msg)


jumpByTime : LockState -> MediaPlayerId -> Time -> Model -> ( Model, Cmd Msg )
jumpByTime lockState id timeOffset model =
    let
        update mediaPlayer =
            MediaPlayer.updateCurrentTime
                (mediaPlayer.currentTime + timeOffset)
                mediaPlayer

        msg mediaPlayer domId =
            Ports.Seek domId mediaPlayer.currentTime

        newLoopState =
            case model.loopState of
                Normal ->
                    Normal

                Looping { audioTime, videoTime } ->
                    let
                        ( audioOffset, videoOffset ) =
                            case lockState of
                                Locked ->
                                    ( timeOffset, timeOffset )

                                Unlocked ->
                                    case id of
                                        Audio ->
                                            ( timeOffset, 0 )

                                        Video ->
                                            ( 0, timeOffset )
                    in
                    Looping
                        { audioTime =
                            clamp 0 model.audio.duration (audioTime + audioOffset)
                        , videoTime =
                            clamp 0 model.video.duration (videoTime + videoOffset)
                        , restarting = False
                        }
    in
    updateLockAware
        lockState
        { model | loopState = newLoopState }
        id
        update
        msg


jumpByPoint : LockState -> MediaPlayerId -> Direction -> Model -> ( Model, Cmd Msg )
jumpByPoint lockState id direction model =
    let
        ( audioCurrentTime, videoCurrentTime ) =
            Utils.getCurrentTimes model

        calculateTime getTime currentTime mediaPlayer =
            Utils.getClosestPoint getTime direction currentTime model.points
                |> Maybe.map getTime
                |> Maybe.withDefault
                    (case direction of
                        Forward ->
                            mediaPlayer.duration

                        Backward ->
                            0
                    )

        audioTime =
            calculateTime .audioTime audioCurrentTime model.audio

        videoTime =
            calculateTime .videoTime videoCurrentTime model.video

        update =
            MediaPlayer.updateCurrentTime

        msg =
            Ports.Seek
    in
    case lockState of
        Locked ->
            let
                newModel =
                    { model
                        | audio = update audioTime model.audio
                        , video = update videoTime model.video
                    }
            in
            ( updateLoopTimes newModel
            , Cmd.batch
                [ Ports.send (msg DomId.Audio audioTime)
                , Ports.send (msg DomId.Video videoTime)
                ]
            )

        Unlocked ->
            let
                time =
                    case id of
                        Audio ->
                            audioTime

                        Video ->
                            videoTime
            in
            ( updateMediaPlayer (update time) id model |> updateLoopTimes
            , Ports.send (msg (domIdFromMediaPlayerId id) time)
            )


updateCurrentTime : MediaPlayerId -> Time -> Model -> ( Model, Cmd Msg )
updateCurrentTime id currentTime model =
    let
        ( cmd, newLoopState ) =
            case model.loopState of
                Normal ->
                    ( Cmd.none, Normal )

                Looping ({ audioTime, videoTime, restarting } as loopDetails) ->
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
                        , Looping { loopDetails | restarting = True }
                        )
                    else
                        ( Cmd.none
                        , Looping { loopDetails | restarting = shouldRestart }
                        )
    in
    ( updateMediaPlayer
        (MediaPlayer.updateCurrentTime currentTime)
        id
        { model | loopState = newLoopState }
    , cmd
    )


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
            in
            ( updateLoopTimes newModel
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
            ( updateMediaPlayer (update time) id model |> updateLoopTimes
            , Ports.send (msg (domIdFromMediaPlayerId id) time)
            )


updateLoopTimes : Model -> Model
updateLoopTimes model =
    let
        newLoopState =
            case model.loopState of
                Normal ->
                    Normal

                Looping _ ->
                    Looping
                        { audioTime = model.audio.currentTime
                        , videoTime = model.video.currentTime
                        , restarting = False
                        }
    in
    { model | loopState = newLoopState }


addError : Error -> Model -> Model
addError error model =
    { model | errors = error :: model.errors }


pointsSaveFilename : String -> String
pointsSaveFilename audioName =
    let
        ( base, extension ) =
            Utils.splitExtension audioName

        suffix =
            "points.json"
    in
    if String.isEmpty base then
        suffix
    else
        base ++ "_" ++ suffix


updateKeyboardShortcuts : String -> String -> KeyboardShortcuts -> KeyboardShortcuts
updateKeyboardShortcuts firstKey secondKey keyboardShortcuts =
    let
        firstKeyShortcut =
            Dict.get firstKey keyboardShortcuts

        secondKeyShortcut =
            Dict.get secondKey keyboardShortcuts
    in
    keyboardShortcuts
        |> Dict.update firstKey (always secondKeyShortcut)
        |> Dict.update secondKey (always firstKeyShortcut)
