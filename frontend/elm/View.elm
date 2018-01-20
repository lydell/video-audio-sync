module View exposing (view)

import DomId
import Html exposing (Attribute, Html, audio, button, div, p, span, text, video)
import Html.Attributes exposing (attribute, class, classList, src, style, title, type_, width)
import Html.Attributes.Custom exposing (muted)
import Html.Events exposing (on, onClick)
import Html.Events.Custom exposing (MetaDataDetails, MouseDownDetails, onAudioMetaData, onClickWithButton, onMouseDown, onTimeUpdate, onVideoMetaData, preventContextMenu)
import Json.Decode as Decode exposing (Decoder)
import MediaPlayer exposing (MediaPlayer, PlayState(Paused, Playing))
import Svg
import Svg.Attributes as Svg
import Types exposing (..)
import Utils


progressBarHeight : Float
progressBarHeight =
    10


progressBarSpacing : Float
progressBarSpacing =
    15


progressBarMouseAreaExtra : Float
progressBarMouseAreaExtra =
    progressBarSpacing - 4


svgHeight : Float
svgHeight =
    (progressBarHeight * 2) + progressBarSpacing


view : Model -> Html Msg
view model =
    div [ class "Layout" ]
        [ viewMedia model
        , viewControls model
        ]


viewMedia : Model -> Html Msg
viewMedia model =
    let
        aspectRatio =
            if model.video.size.height == 0 then
                1
            else
                model.video.size.width / model.video.size.height

        maxWidth =
            model.videoArea.width

        maxHeight =
            model.videoArea.height

        heightIfMaxWidth =
            maxWidth / aspectRatio

        clampedWidth =
            if heightIfMaxWidth <= maxHeight then
                maxWidth
            else
                maxHeight * aspectRatio
    in
    div [ class "Layout-videoWrapper", DomId.toHtml DomId.VideoArea ]
        [ video
            ([ src "/sommaren_video.mp4"
             , width (truncate clampedWidth)
             , muted True
             , onVideoMetaData (MetaData Video)
             , onTimeUpdate (CurrentTime Video)
             , DomId.toHtml DomId.Video
             , class "Layout-video"
             ]
                ++ playEvents Video
            )
            []
        , audio
            ([ src "/sommaren_audio.aac"
             , onAudioMetaData (MetaData Audio)
             , onTimeUpdate (CurrentTime Audio)
             , DomId.toHtml DomId.Audio
             ]
                ++ playEvents Audio
            )
            []
        ]


viewControls : Model -> Html Msg
viewControls model =
    div [ class "Layout-controls", preventContextMenu ]
        [ mediaPlayerToolbar Video model.video model.loopState
        , viewGraphics model
        , mediaPlayerToolbar Audio model.audio model.loopState
        , generalToolbar model
        ]


viewGraphics : Model -> Html Msg
viewGraphics model =
    let
        svgWidth =
            model.controlsArea.width

        viewBoxString =
            [ 0, 0, svgWidth, svgHeight ]
                |> List.map toString
                |> String.join " "

        progressBarX =
            0

        maxProgressBarWidth =
            max 1 svgWidth

        longestDuration =
            max model.video.duration model.audio.duration

        scale =
            longestDuration / maxProgressBarWidth

        toScale number =
            if scale == 0 then
                1
            else
                number / scale

        videoY =
            0

        audioY =
            videoY + progressBarHeight + progressBarSpacing

        ( videoCurrentTime, audioCurrentTime ) =
            case model.loopState of
                Normal ->
                    ( model.video.currentTime
                    , model.audio.currentTime
                    )

                Looping audioTime videoTime ->
                    ( videoTime
                    , audioTime
                    )
    in
    div
        [ DomId.toHtml DomId.GraphicsArea
        , class "Graphics"
        , style [ ( "height", toString svgHeight ++ "px" ) ]
        ]
        [ Svg.svg
            [ Svg.viewBox viewBoxString
            , Svg.class "Graphics-svg"
            ]
            [ progressBar
                { maxValue = toScale model.video.duration
                , currentValue = toScale videoCurrentTime
                , x = progressBarX
                , y = videoY
                , onDragStart = DragStart Video
                }
            , progressBar
                { maxValue = toScale model.audio.duration
                , currentValue = toScale audioCurrentTime
                , x = progressBarX
                , y = audioY
                , onDragStart = DragStart Audio
                }
            ]
        ]


type alias ProgressBarDetails msg =
    { maxValue : Float
    , currentValue : Float
    , x : Float
    , y : Float
    , onDragStart : DragBar -> MouseDownDetails -> msg
    }


progressBar : ProgressBarDetails msg -> Html msg
progressBar { maxValue, currentValue, x, y, onDragStart } =
    let
        width =
            maxValue

        progressWidth =
            currentValue
    in
    Svg.g []
        [ Svg.rect
            [ Svg.x (toString x)
            , Svg.y (toString y)
            , Svg.width (toString width)
            , Svg.height (toString progressBarHeight)
            , Svg.class "ProgressBar"
            ]
            []
        , Svg.rect
            [ Svg.x (toString x)
            , Svg.y (toString y)
            , Svg.width (toString progressWidth)
            , Svg.height (toString progressBarHeight)
            , Svg.class "ProgressBar-progress"
            ]
            []
        , Svg.line
            [ Svg.x1 (toString progressWidth)
            , Svg.y1 (toString y)
            , Svg.x2 (toString progressWidth)
            , Svg.y2 (toString (y + progressBarHeight))
            , Svg.class "ProgressBar-current"
            ]
            []
        , Svg.rect
            [ Svg.x (toString x)
            , Svg.y (toString (y - progressBarMouseAreaExtra / 2))
            , Svg.width (toString width)
            , Svg.height (toString (progressBarHeight + progressBarMouseAreaExtra))
            , Svg.class "ProgressBar-mouseArea"
            , onMouseDown <|
                onDragStart
                    { x = x
                    , width = width
                    }
            ]
            []
        ]


mediaPlayerToolbar : MediaPlayerId -> MediaPlayer -> LoopState -> Html Msg
mediaPlayerToolbar id mediaPlayer loopState =
    let
        ( name, icon ) =
            case id of
                Audio ->
                    ( "audio", "volume-up" )

                Video ->
                    ( "video", "video-camera" )

        ( playPauseTitle, playPauseIcon ) =
            case ( mediaPlayer.playState, loopState ) of
                ( Playing, Normal ) ->
                    ( "Playing " ++ name ++ ". Click to pause."
                    , "pause"
                    )

                ( Playing, Looping _ _ ) ->
                    ( "Looping. Click to pause."
                    , "pause-circle-o"
                    )

                ( Paused, Normal ) ->
                    ( "Paused " ++ name ++ ". Click to play."
                    , "play"
                    )

                ( Paused, Looping _ _ ) ->
                    ( "Paused. Click to play."
                    , "play-circle-o"
                    )
    in
    toolbar
        [ buttonGroup
            [ { icon = icon
              , title = "TODO"
              , pressed = False
              , attributes = []
              }
            ]
        , buttonGroup
            [ { icon = playPauseIcon
              , title = playPauseTitle
              , pressed =
                    case mediaPlayer.playState of
                        Playing ->
                            True

                        Paused ->
                            False
              , attributes =
                    [ onClickWithButton <|
                        case mediaPlayer.playState of
                            Playing ->
                                Pause id

                            Paused ->
                                Play id
                    ]
              }
            ]
        , p []
            [ text <|
                Utils.formatDuration mediaPlayer.currentTime
                    ++ " / "
                    ++ Utils.formatDuration mediaPlayer.duration
            ]
        ]


generalToolbar : Model -> Html Msg
generalToolbar model =
    toolbar
        [ buttonGroup
            [ { icon = "repeat"
              , title =
                    case model.loopState of
                        Normal ->
                            "Video and audio play in normally. Click to loop."

                        Looping _ _ ->
                            "Video and audio play loop around their current positions. Click to play normally."
              , pressed =
                    case model.loopState of
                        Normal ->
                            False

                        Looping _ _ ->
                            True
              , attributes =
                    [ onClick <|
                        case model.loopState of
                            Normal ->
                                GoLooping

                            Looping _ _ ->
                                GoNormal
                    ]
              }
            ]
        ]


toolbar : List (Html msg) -> Html msg
toolbar children =
    div [ class "Toolbar" ] children


type alias ButtonDetails msg =
    { icon : String
    , title : String
    , pressed : Bool
    , attributes : List (Attribute msg)
    }


buttonGroup : List (ButtonDetails msg) -> Html msg
buttonGroup buttons =
    div [ class "ButtonGroup" ] (List.map buttonGroupButton buttons)


buttonGroupButton : ButtonDetails msg -> Html msg
buttonGroupButton buttonDetails =
    button
        ([ type_ "button"
         , title buttonDetails.title
         , classList
            [ ( "ButtonGroup-button", True )
            , ( "is-pressed", buttonDetails.pressed )
            ]
         ]
            ++ buttonDetails.attributes
        )
        [ fontawesome buttonDetails.icon ]


fontawesome : String -> Html msg
fontawesome name =
    span
        [ attribute "aria-hidden" "true"
        , class ("fa fa-fw fa-" ++ name)
        ]
        []


playEvents : MediaPlayerId -> List (Attribute Msg)
playEvents id =
    let
        decoder =
            decodePlayState id
    in
    [ on "abort" decoder
    , on "ended" decoder
    , on "error" decoder
    , on "pause" decoder
    , on "play" decoder
    , on "playing" decoder
    , on "stalled" decoder
    , on "suspend" decoder
    ]


decodePlayState : MediaPlayerId -> Decoder Msg
decodePlayState id =
    Decode.at [ "currentTarget", "paused" ] Decode.bool
        |> Decode.map
            (\paused ->
                case paused of
                    True ->
                        ExternalPause id

                    False ->
                        ExternalPlay id
            )


togglePlayState : MediaPlayerId -> PlayState -> Attribute Msg
togglePlayState id playState =
    onClickWithButton <|
        case playState of
            Playing ->
                Pause id

            Paused ->
                Play id


toPoints : List ( number, number ) -> String
toPoints coords =
    coords
        |> List.map (\( x, y ) -> toString x ++ "," ++ toString y)
        |> String.join " "
