module View exposing (view)

import DomId
import Html exposing (Attribute, Html, audio, button, div, p, span, text, video)
import Html.Attributes exposing (attribute, class, id, src, style, title, type_, width)
import Html.Attributes.Custom exposing (muted)
import Html.Events exposing (on, onClick)
import Html.Events.Custom exposing (MetaDataDetails, onAudioMetaData, onMouseDown, onTimeUpdate, onVideoMetaData, preventContextMenu)
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
        , div [ class "Layout-controls" ]
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
            , fontawesome "lock"
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
                        , Svg.width (toString (toScale model.video.currentTime))
                        , Svg.height (toString lineHeight)
                        , Svg.class "Progress-elapsed"
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString audioLineY)
                        , Svg.width (toString (toScale model.audio.currentTime))
                        , Svg.height (toString lineHeight)
                        , Svg.class "Progress-elapsed"
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString (videoLineY - lineHoverExtra / 2))
                        , Svg.width (toString videoLineWidth)
                        , Svg.height (toString (lineHeight + lineHoverExtra))
                        , Svg.class "Progress-hover"
                        , preventContextMenu
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
                        , preventContextMenu
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
                        Pause id

                    False ->
                        Play id
            )


togglePlayState : MediaPlayerId -> PlayState -> Attribute Msg
togglePlayState id playState =
    onClick <|
        case playState of
            Playing ->
                Pause id

            Paused ->
                Play id
