module View exposing (view)

import DomId
import Html exposing (Attribute, Html, audio, button, div, p, span, text, video)
import Html.Attributes exposing (attribute, class, id, src, style, title, type_, width)
import Html.Attributes.Custom exposing (muted)
import Html.Events exposing (on, onClick)
import Html.Events.Custom exposing (MetaDataDetails, onAudioMetaData, onClickWithButton, onMouseDown, onTimeUpdate, onVideoMetaData, preventContextMenu)
import Json.Decode as Decode exposing (Decoder)
import MediaPlayer exposing (PlayState(Paused, Playing))
import Svg
import Svg.Attributes as Svg
import Types exposing (..)
import Utils


lineHeight : Float
lineHeight =
    10


lineMargin : Float
lineMargin =
    10


lineBetween : Float
lineBetween =
    20


lineHoverExtra : Float
lineHoverExtra =
    lineBetween - 4


svgHeight : Float
svgHeight =
    (lineHeight * 2) + lineBetween


view : Model -> Html Msg
view model =
    let
        svgWidth =
            model.controlsArea.width

        viewBoxString =
            [ 0, 0, svgWidth, svgHeight ]
                |> List.map toString
                |> String.join " "

        ratio =
            if model.audio.duration == 0 then
                1
            else
                model.video.duration / model.audio.duration

        maxLineWidth =
            max 1 (svgWidth - lineMargin * 2)

        ( videoLineWidth, audioLineWidth, scale ) =
            if ratio >= 1 then
                ( maxLineWidth
                , maxLineWidth / ratio
                , model.video.duration / maxLineWidth
                )
            else
                ( maxLineWidth * ratio
                , maxLineWidth
                , model.audio.duration / maxLineWidth
                )

        toScale number =
            if scale == 0 then
                1
            else
                number / scale

        videoLineY =
            0

        audioLineY =
            videoLineY + lineHeight + lineBetween

        ( videoWidth, audioWidth ) =
            case model.loopState of
                Normal ->
                    ( toScale model.video.currentTime
                    , toScale model.audio.currentTime
                    )

                Looping audioTime videoTime ->
                    ( toScale videoTime
                    , toScale audioTime
                    )

        currentTime =
            { x1 = lineMargin + videoWidth
            , y1 = videoLineY
            , x2 = lineMargin + videoWidth
            , y2 = videoLineY + lineHeight
            , x3 = lineMargin + audioWidth
            , y3 = audioLineY
            , x4 = lineMargin + audioWidth
            , y4 = audioLineY + lineHeight
            }

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
    div [ class "Layout" ]
        [ div [ class "Layout-video", id (DomId.toString DomId.VideoArea) ]
            [ video
                ([ src "/sommaren_video.mp4"
                 , width (truncate clampedWidth)
                 , muted True
                 , onVideoMetaData (MetaData Video)
                 , onTimeUpdate (CurrentTime Video)
                 , id (DomId.toString DomId.Video)
                 ]
                    ++ playEvents Video
                )
                []
            , audio
                ([ src "/sommaren_audio.aac"
                 , onAudioMetaData (MetaData Audio)
                 , onTimeUpdate (CurrentTime Audio)
                 , id (DomId.toString DomId.Audio)
                 ]
                    ++ playEvents Audio
                )
                []
            ]
        , div [ class "Layout-controls", preventContextMenu ]
            [ fontawesome "video-camera"
            , div [ class "Toolbar" ]
                [ button
                    [ type_ "button"
                    , title <|
                        case model.video.playState of
                            Playing ->
                                "Pause video"

                            Paused ->
                                "Play video"
                    , togglePlayState Video model.video.playState
                    , on "contextmenu" (Decode.succeed NoOp)
                    ]
                    [ fontawesome <|
                        case model.video.playState of
                            Playing ->
                                "pause"

                            Paused ->
                                "play"
                    ]
                , p []
                    [ text <|
                        Utils.formatDuration model.video.currentTime
                            ++ " / "
                            ++ Utils.formatDuration model.video.duration
                    ]
                ]
            , div [] []
            , div
                [ id (DomId.toString DomId.ControlsArea)
                , class "Progress"
                , style [ ( "height", toString svgHeight ++ "px" ) ]
                ]
                [ Svg.svg
                    [ Svg.viewBox viewBoxString
                    , Svg.class "Progress-svg"
                    ]
                    [ Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString videoLineY)
                        , Svg.width (toString videoLineWidth)
                        , Svg.height (toString lineHeight)
                        , Svg.class "Progress-line"
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString audioLineY)
                        , Svg.width (toString audioLineWidth)
                        , Svg.height (toString lineHeight)
                        , Svg.class "Progress-line"
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString videoLineY)
                        , Svg.width (toString videoWidth)
                        , Svg.height (toString lineHeight)
                        , Svg.class "Progress-elapsed"
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString audioLineY)
                        , Svg.width (toString audioWidth)
                        , Svg.height (toString lineHeight)
                        , Svg.class "Progress-elapsed"
                        ]
                        []
                    , Svg.line
                        [ Svg.x1 (toString currentTime.x1)
                        , Svg.y1 (toString currentTime.y1)
                        , Svg.x2 (toString currentTime.x2)
                        , Svg.y2 (toString currentTime.y2)
                        , Svg.class "Progress-currentTime"
                        ]
                        []
                    , Svg.line
                        [ Svg.x1 (toString currentTime.x3)
                        , Svg.y1 (toString currentTime.y3)
                        , Svg.x2 (toString currentTime.x4)
                        , Svg.y2 (toString currentTime.y4)
                        , Svg.class "Progress-currentTime"
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString (videoLineY - lineHoverExtra / 2))
                        , Svg.width (toString videoLineWidth)
                        , Svg.height (toString (lineHeight + lineHoverExtra))
                        , Svg.class "Progress-hover"
                        , onMouseDown
                            (DragStart
                                Video
                                { x = lineMargin
                                , width = videoLineWidth
                                }
                            )
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString (audioLineY - lineHoverExtra / 2))
                        , Svg.width (toString audioLineWidth)
                        , Svg.height (toString (lineHeight + lineHoverExtra))
                        , Svg.class "Progress-hover"
                        , onMouseDown
                            (DragStart
                                Audio
                                { x = lineMargin
                                , width = audioLineWidth
                                }
                            )
                        ]
                        []
                    ]
                ]
            , fontawesome "volume-up"
            , div [ class "Toolbar" ]
                [ button
                    [ type_ "button"
                    , title <|
                        case model.audio.playState of
                            Playing ->
                                "Pause audio"

                            Paused ->
                                "Play audio"
                    , togglePlayState Audio model.audio.playState
                    ]
                    [ fontawesome <|
                        case model.audio.playState of
                            Playing ->
                                "pause"

                            Paused ->
                                "play"
                    ]
                , p []
                    [ text <|
                        Utils.formatDuration model.audio.currentTime
                            ++ " / "
                            ++ Utils.formatDuration model.audio.duration
                    ]
                ]
            , div [] []
            , div [ class "Toolbar" ]
                [ button
                    [ type_ "button"
                    , title <|
                        case model.loopState of
                            Normal ->
                                "Video and audio play in normally. Click to loop."

                            Looping _ _ ->
                                "Video and audio play loop around their current positions. Click to play normally."
                    , onClick <|
                        case model.loopState of
                            Normal ->
                                GoLooping

                            Looping _ _ ->
                                GoNormal
                    ]
                    [ fontawesome <|
                        case model.loopState of
                            Normal ->
                                "repeat"

                            Looping _ _ ->
                                "refresh"
                    ]
                ]
            ]
        ]


fontawesome : String -> Html msg
fontawesome name =
    span
        [ attribute "aria-hidden" "true"
        , class ("fa fa-" ++ name)
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
