module View exposing (view)

import DomId
import Html exposing (Attribute, Html, audio, button, div, p, span, text, video)
import Html.Attributes exposing (attribute, class, id, property, src, style, title, type_, width)
import Html.Events exposing (on, onClick, onMouseDown, onWithOptions)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Mouse
import Svg
import Svg.Attributes as Svg
import Time exposing (Time)
import Types exposing (..)


lineHeight : Int
lineHeight =
    10


lineMargin : Int
lineMargin =
    10


lineBetween : Int
lineBetween =
    20


lineHoverExtra : Int
lineHoverExtra =
    lineBetween - 4


svgHeight : Int
svgHeight =
    (lineHeight * 2) + lineBetween


view : Model -> Html Msg
view model =
    let
        svgWidth =
            model.controlsArea.width

        viewBoxString =
            [ 0, 0, svgWidth, toFloat svgHeight ]
                |> List.map toString
                |> String.join " "

        ratio =
            if model.audioDuration == 0 then
                1
            else
                model.videoDuration / model.audioDuration

        maxLineWidth =
            max 1 (svgWidth - toFloat lineMargin * 2)

        ( videoLineWidth, audioLineWidth, scale ) =
            if ratio >= 1 then
                ( maxLineWidth
                , maxLineWidth / ratio
                , model.videoDuration / maxLineWidth
                )
            else
                ( maxLineWidth * ratio
                , maxLineWidth
                , model.audioDuration / maxLineWidth
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
            if model.videoSize.height == 0 then
                1
            else
                model.videoSize.width / model.videoSize.height

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
        [ div [ class "Layout-video", id (DomId.toString DomId.IdVideoArea) ]
            [ video
                ([ src "/sommaren_video.mp4"
                 , width (truncate clampedWidth)
                 , property "muted" (Encode.bool True)
                 , on "loadedmetadata" (decodeVideoMetaData VideoMetaData)
                 , on "timeupdate" (decodeMediaCurrentTime VideoCurrentTime)
                 , id (DomId.toString DomId.IdVideo)
                 ]
                    ++ playEvents VideoPlayState
                )
                []
            , audio
                ([ src "/sommaren_audio.aac"
                 , on "loadedmetadata" (decodeAudioMetaData AudioMetaData)
                 , on "timeupdate" (decodeMediaCurrentTime AudioCurrentTime)
                 , id (DomId.toString DomId.IdAudio)
                 ]
                    ++ playEvents AudioPlayState
                )
                []
            ]
        , div [ class "Layout-controls" ]
            [ fontawesome "video-camera"
            , div [ class "Toolbar" ]
                [ button
                    [ type_ "button"
                    , title <|
                        if model.videoPlaying then
                            "Pause video"
                        else
                            "Play video"
                    , onClick <|
                        VideoPlayState (not model.videoPlaying)
                    ]
                    [ if model.videoPlaying then
                        fontawesome "pause"
                      else
                        fontawesome "play"
                    ]
                , p []
                    [ text <|
                        formatDuration model.videoCurrentTime
                            ++ " / "
                            ++ formatDuration model.videoDuration
                    ]
                ]
            , fontawesome "lock"
            , div
                [ id (DomId.toString DomId.IdControlsArea)
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
                        , Svg.width (toString (toScale model.videoCurrentTime))
                        , Svg.height (toString lineHeight)
                        , Svg.class "Progress-elapsed"
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString audioLineY)
                        , Svg.width (toString (toScale model.audioCurrentTime))
                        , Svg.height (toString lineHeight)
                        , Svg.class "Progress-elapsed"
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString (videoLineY - lineHoverExtra // 2))
                        , Svg.width (toString videoLineWidth)
                        , Svg.height (toString (lineHeight + lineHoverExtra))
                        , Svg.class "Progress-hover"
                        , preventContextMenu
                        , onMouseDown
                            (DragStart
                                Video
                                { x = toFloat lineMargin
                                , width = videoLineWidth
                                }
                            )
                        ]
                        []
                    , Svg.rect
                        [ Svg.x (toString lineMargin)
                        , Svg.y (toString (audioLineY - lineHoverExtra // 2))
                        , Svg.width (toString audioLineWidth)
                        , Svg.height (toString (lineHeight + lineHoverExtra))
                        , Svg.class "Progress-hover"
                        , preventContextMenu
                        , onMouseDown
                            (DragStart
                                Audio
                                { x = toFloat lineMargin
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
                        if model.audioPlaying then
                            "Pause audio"
                        else
                            "Play audio"
                    , onClick <|
                        AudioPlayState (not model.audioPlaying)
                    ]
                    [ if model.audioPlaying then
                        fontawesome "pause"
                      else
                        fontawesome "play"
                    ]
                , p []
                    [ text <|
                        formatDuration model.audioCurrentTime
                            ++ " / "
                            ++ formatDuration model.audioDuration
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


playEvents : (Bool -> value) -> List (Html.Attribute value)
playEvents msg =
    let
        decoder =
            decodeMediaPlayState msg
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


decodeMediaPlayState : (Bool -> msg) -> Decoder msg
decodeMediaPlayState msg =
    Decode.at [ "currentTarget", "paused" ] Decode.bool
        |> Decode.map (not >> msg)


decodeVideoMetaData : (VideoMetaDataDetails -> msg) -> Decoder msg
decodeVideoMetaData msg =
    Decode.map3
        (\duration width height ->
            msg
                { duration = duration * Time.second
                , width = width
                , height = height
                }
        )
        (Decode.at [ "currentTarget", "duration" ] Decode.float)
        (Decode.at [ "currentTarget", "videoWidth" ] Decode.float)
        (Decode.at [ "currentTarget", "videoHeight" ] Decode.float)


decodeAudioMetaData : (AudioMetaDataDetails -> msg) -> Decoder msg
decodeAudioMetaData msg =
    Decode.at [ "currentTarget", "duration" ] Decode.float
        |> Decode.map
            (\duration ->
                msg
                    { duration = duration * Time.second
                    }
            )


decodeMediaCurrentTime : (Time -> msg) -> Decoder msg
decodeMediaCurrentTime msg =
    Decode.at [ "currentTarget", "currentTime" ] Decode.float
        |> Decode.map ((*) Time.second >> msg)


formatDuration : Time -> String
formatDuration duration =
    let
        ( hours, hoursRest ) =
            divRem duration Time.hour

        ( minutes, minutesRest ) =
            divRem hoursRest Time.minute

        ( seconds, secondsRest ) =
            divRem minutesRest Time.second

        ( milliseconds, millisecondsRest ) =
            divRem secondsRest Time.millisecond

        pad number numChars =
            String.padLeft numChars '0' (toString number)
    in
    pad hours 2
        ++ ":"
        ++ pad minutes 2
        ++ ":"
        ++ pad seconds 2
        ++ "."
        ++ pad milliseconds 3


divRem : Float -> Float -> ( Int, Float )
divRem numerator divisor =
    let
        whole =
            truncate (numerator / divisor)

        rest =
            numerator - toFloat whole * divisor
    in
    ( whole, rest )


onMouseDown : (Mouse.Position -> msg) -> Attribute msg
onMouseDown msg =
    onWithOptions
        "mousedown"
        { stopPropagation = False, preventDefault = True }
        (decodeMousePosition |> Decode.map msg)


decodeMousePosition : Decoder Mouse.Position
decodeMousePosition =
    Decode.map2 Mouse.Position
        (Decode.field "pageX" Decode.int)
        (Decode.field "pageY" Decode.int)


preventContextMenu : Attribute msg
preventContextMenu =
    attribute "oncontextmenu" "return false"
