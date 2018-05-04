module Main exposing (..)

import Data.Buttons as Buttons
import Data.DomId as DomId exposing (DomId)
import Data.Error as Error exposing (Error)
import Data.File as File
import Data.KeyboardShortcuts as KeyboardShortcuts
import Data.MediaPlayer as MediaPlayer exposing (MediaPlayer)
import Data.Model as Model exposing (..)
import Data.Point as Point exposing (Direction(Backward, Forward))
import Data.StateSyncModel as StateSyncModel
import Dict
import Html
import Html.Events.Custom exposing (MouseButton(Left, Right))
import Json.Decode as Decode
import Json.Encode as Encode
import ModelUtils
import Mouse
import Ports
import Task
import Time exposing (Time)
import Utils
import View
import Window


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
    , keyboardShortcuts : Decode.Value
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        emptyModel =
            Model.empty

        emptyMediaPlayer =
            MediaPlayer.empty

        emptyStateSyncModel =
            StateSyncModel.empty

        withLocalName maybeName =
            case maybeName of
                Just name ->
                    { emptyMediaPlayer | name = name, url = Just ("/" ++ name) }

                Nothing ->
                    emptyMediaPlayer

        keyboardShortcutsResult =
            Decode.decodeValue (Decode.nullable KeyboardShortcuts.decoder)
                flags.keyboardShortcuts

        keyboardShortcuts =
            case keyboardShortcutsResult of
                Ok (Just shortcuts) ->
                    shortcuts

                Ok Nothing ->
                    Buttons.defaultKeyboardShortCuts

                Err message ->
                    let
                        _ =
                            Debug.log "Failed to decode saved keyboardShortcuts"
                                { message = message, data = flags.keyboardShortcuts }
                    in
                    Buttons.defaultKeyboardShortCuts
    in
    ( { emptyModel
        | audio = withLocalName flags.audio
        , video = withLocalName flags.video
        , keyboardShortcuts = keyboardShortcuts
      }
    , Cmd.batch
        [ Task.perform WindowSize Window.size
        , Ports.send
            (Ports.StateSync
                { emptyStateSyncModel | keyboardShortcuts = keyboardShortcuts }
            )
        ]
    )


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

        warnOnClose =
            case newModel.points of
                [] ->
                    Nothing

                _ ->
                    Just "Make sure you have saved your points before leaving. They will be lost otherwise."
    in
    ( newModel
    , Cmd.batch
        [ cmd
        , Ports.send
            (Ports.StateSync
                { keyboardShortcuts = newModel.keyboardShortcuts
                , editingKeyboardShortcuts = newModel.editKeyboardShortcuts /= NotEditing
                , warnOnClose = warnOnClose
                }
            )
        ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        JsMessage messageResult ->
            case messageResult of
                Ok incomingMessage ->
                    updateIncoming incomingMessage model

                Err message ->
                    let
                        _ =
                            Debug.log "incomingMessage error" message
                    in
                    ( model
                    , Cmd.none
                    )

        MediaErrorMsg id ->
            let
                name =
                    case id of
                        Audio ->
                            { name = model.audio.name
                            , fileType = File.AudioFile
                            }

                        Video ->
                            { name = model.video.name
                            , fileType = File.VideoFile
                            }

                newModel =
                    model
                        |> updateMediaPlayer
                            (always MediaPlayer.empty)
                            id
                        |> addError (Error.Media name)
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
            ( { model | points = point :: model.points }
            , Cmd.none
            )

        RemovePoint point ->
            let
                newPoints =
                    List.filter ((/=) point) model.points
            in
            ( { model | points = newPoints }
            , Cmd.none
            )

        RemoveAllPoints ->
            ( { model | points = [], confirmRemoveAllPointsModalOpen = False }
            , Cmd.none
            )

        ConfirmRemoveAllPoints ->
            ( { model | confirmRemoveAllPointsModalOpen = True }
            , Cmd.none
            )

        CloseRemoveAllPoints ->
            ( { model | confirmRemoveAllPointsModalOpen = False }
            , Cmd.none
            )

        Save ->
            let
                content =
                    model.points
                        |> Point.encode
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
                            File.AudioFile

                        Video ->
                            File.VideoFile
            in
            ( model
            , Ports.send (Ports.OpenFile fileType)
            )

        OpenPoints ->
            ( model
            , Ports.send (Ports.OpenFile File.JsonFile)
            )

        OpenConfirmedPoints points ->
            ( { model | points = points, confirmOpenPoints = Nothing }
            , Cmd.none
            )

        CloseOpenPoints ->
            ( { model | confirmOpenPoints = Nothing }
            , Cmd.none
            )

        OpenMultiple ->
            ( model
            , Ports.send Ports.OpenMultipleFiles
            )

        CloseErrorsModal ->
            ( { model | errors = [] }
            , Cmd.none
            )

        OpenPointsWarningsModal ->
            ( { model | pointsWarningsModalOpen = True }
            , Cmd.none
            )

        ClosePointsWarningsModal ->
            ( { model | pointsWarningsModalOpen = False }
            , Cmd.none
            )

        ToggleShowKeyboardShortcuts ->
            ( { model | showKeyboardShortcuts = not model.showKeyboardShortcuts }
            , Cmd.none
            )

        ToggleEditKeyboardShortcuts ->
            ( { model
                | editKeyboardShortcuts =
                    if model.editKeyboardShortcuts == NotEditing then
                        WaitingForFirstKey
                            { unavailableKey = Nothing
                            , justChangedKeys = []
                            }
                    else
                        NotEditing
              }
            , Cmd.none
            )

        ResetKeyboardShortcuts ->
            let
                keyboardShortcuts =
                    Buttons.defaultKeyboardShortCuts
            in
            ( { model
                | editKeyboardShortcuts =
                    WaitingForFirstKey
                        { unavailableKey = Nothing
                        , justChangedKeys = []
                        }
                , keyboardShortcuts = keyboardShortcuts
                , undoKeyboardShortcuts = Just model.keyboardShortcuts
              }
            , Cmd.none
            )

        UndoResetKeyboardShortcuts ->
            case model.undoKeyboardShortcuts of
                Just keyboardShortcuts ->
                    ( { model
                        | keyboardShortcuts = keyboardShortcuts
                        , undoKeyboardShortcuts = Nothing
                      }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Cmd.none )

        OpenHelpModal ->
            ( { model | helpModalOpen = True }
            , Cmd.none
            )

        CloseHelpModal ->
            ( { model | helpModalOpen = False }
            , Cmd.none
            )

        WindowSize size ->
            ( { model | windowSize = size }
            , Cmd.batch
                [ Ports.send (Ports.MeasureArea DomId.VideoArea)
                , Ports.send (Ports.MeasureArea DomId.GraphicsArea)
                ]
            )


updateIncoming : Ports.IncomingMessage -> Model -> ( Model, Cmd Msg )
updateIncoming msg model =
    case msg of
        Ports.AreaMeasurement id area ->
            case id of
                DomId.VideoArea ->
                    ( { model | videoArea = area }
                    , Cmd.none
                    )

                DomId.GraphicsArea ->
                    ( { model | controlsArea = area }
                    , Cmd.none
                    )

                _ ->
                    let
                        _ =
                            Debug.log "unexpected AreaMeasurement" id
                    in
                    ( model
                    , Cmd.none
                    )

        Ports.OpenedFileAsText { name, fileType, text } ->
            let
                newModel =
                    case fileType of
                        File.JsonFile ->
                            openPointsJson name text model

                        _ ->
                            let
                                _ =
                                    Debug.log "unexpected OpenedFileAsText" fileType
                            in
                            model
            in
            ( newModel
            , Cmd.none
            )

        Ports.OpenedFileAsUrl { name, fileType, url } ->
            let
                empty =
                    MediaPlayer.empty

                newMediaPlayer =
                    { empty | name = name, url = Just url }

                newModel =
                    case fileType of
                        File.AudioFile ->
                            { model | audio = newMediaPlayer }

                        File.VideoFile ->
                            { model | video = newMediaPlayer }

                        _ ->
                            let
                                _ =
                                    Debug.log "unexpected OpenedFileAsUrl" fileType
                            in
                            model
            in
            ( newModel
            , Cmd.none
            )

        Ports.InvalidFile details ->
            ( addError (Error.InvalidFile details) model
            , Cmd.none
            )

        Ports.ErroredFile details ->
            ( addError (Error.ErroredFile details) model
            , Cmd.none
            )

        Ports.DragEnter ->
            ( { model | isDraggingFile = True }
            , Cmd.none
            )

        Ports.DragLeave ->
            ( { model | isDraggingFile = False }
            , Cmd.none
            )

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
            case key of
                "Escape" ->
                    ( { model
                        | pointsWarningsModalOpen = False
                        , confirmRemoveAllPointsModalOpen = False
                        , confirmOpenPoints = Nothing
                        , errors = []
                        , showKeyboardShortcuts = False
                        , editKeyboardShortcuts = NotEditing
                        , undoKeyboardShortcuts = Nothing
                        , helpModalOpen = False
                      }
                    , Cmd.none
                    )

                "Tab" ->
                    ( model
                    , Cmd.none
                    )

                _ ->
                    case model.editKeyboardShortcuts of
                        NotEditing ->
                            ( model
                            , case buttonId of
                                Just id ->
                                    Ports.send (Ports.ClickButton id mouseButton)

                                Nothing ->
                                    Cmd.none
                            )

                        WaitingForFirstKey _ ->
                            ( { model
                                | editKeyboardShortcuts =
                                    case buttonId of
                                        Just _ ->
                                            WaitingForSecondKey
                                                { unavailableKey = Nothing
                                                , firstKey = key
                                                }

                                        _ ->
                                            WaitingForFirstKey
                                                { unavailableKey = Just key
                                                , justChangedKeys = []
                                                }
                              }
                            , Cmd.none
                            )

                        WaitingForSecondKey { firstKey } ->
                            if String.length key == 1 then
                                let
                                    keyboardShortcuts =
                                        KeyboardShortcuts.update
                                            firstKey
                                            key
                                            model.keyboardShortcuts
                                in
                                ( { model
                                    | editKeyboardShortcuts =
                                        WaitingForFirstKey
                                            { unavailableKey = Nothing
                                            , justChangedKeys = [ firstKey, key ]
                                            }
                                    , keyboardShortcuts =
                                        keyboardShortcuts
                                    , undoKeyboardShortcuts = Nothing
                                  }
                                , Cmd.none
                                )
                            else
                                ( { model
                                    | editKeyboardShortcuts =
                                        WaitingForSecondKey
                                            { unavailableKey = Just key
                                            , firstKey = firstKey
                                            }
                                  }
                                , Cmd.none
                                )


openPointsJson : String -> String -> Model -> Model
openPointsJson name text model =
    let
        decoded =
            Decode.decodeString Point.decoder text
    in
    case decoded of
        Ok points ->
            case model.points of
                [] ->
                    { model | points = points }

                _ ->
                    { model
                        | confirmOpenPoints =
                            Just { name = name, points = points }
                    }

        Err message ->
            addError
                (Error.InvalidPoints { name = name, message = message })
                model


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
            ModelUtils.getCurrentTimes model

        calculateTime getTime currentTime mediaPlayer =
            Point.getClosestPoint getTime direction currentTime model.points
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
                            min ModelUtils.loopRadius (min audioTime videoTime)

                        endMovement =
                            min ModelUtils.loopRadius <|
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
        ( base, _ ) =
            Utils.splitExtension audioName

        suffix =
            "points.json"
    in
    if String.isEmpty base then
        suffix
    else
        base ++ "_" ++ suffix
