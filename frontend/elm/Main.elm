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
            ( updateMediaPlayer MediaPlayer.play id model
            , Ports.send (Ports.Play (domIdFromMediaPlayerId id))
            )

        Pause id ->
            ( updateMediaPlayer MediaPlayer.pause id model
            , Ports.send (Ports.Pause (domIdFromMediaPlayerId id))
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
    -> DragBar
    -> Mouse.Position
    -> ( Model, Cmd msg )
drag model id dragBar mousePosition =
    let
        offset =
            toFloat mousePosition.x - (model.controlsArea.x + dragBar.x)

        duration =
            case id of
                Audio ->
                    model.audio.duration

                Video ->
                    model.video.duration

        time =
            clamp 0 duration ((offset / dragBar.width) * duration)

        newModel =
            updateMediaPlayer (MediaPlayer.updateCurrentTime time) id model
    in
    ( { newModel | drag = Drag id dragBar mousePosition }
    , Ports.send (Ports.Seek (domIdFromMediaPlayerId id) time)
    )
