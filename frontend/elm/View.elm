module View exposing (view)

import Html exposing (Html, audio, button, div, p, text, video)
import Html.Attributes exposing (class, property, src, type_, width)
import Html.Events exposing (on, onClick)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Svg exposing (circle, line, svg)
import Svg.Attributes exposing (cx, cy, dy, r, strokeWidth, textAnchor, viewBox, x, x1, x2, y, y1, y2)
import Time exposing (Time)
import Types exposing (..)


lineHeight : Int
lineHeight =
    10


lineMargin : Int
lineMargin =
    20


markerWidth : Int
markerWidth =
    10


markerBaseHeight : Int
markerBaseHeight =
    10


svgHeight : Int
svgHeight =
    (markerBaseHeight * 2)
        + (lineHeight * 2)
        + lineMargin


controlsHeight : Int
controlsHeight =
    svgHeight
        + (32 * 2)



-- for the buttons


view : Model -> Html Msg
view model =
    let
        svgWidth =
            toFloat model.windowSize.width

        viewBoxString =
            [ 0, 0, svgWidth, toFloat svgHeight ]
                |> List.map toString
                |> String.join " "

        ratio =
            model.videoDuration / model.audioDuration

        ( videoLineWidth, audioLineWidth, scale ) =
            if ratio >= 1 then
                ( svgWidth, svgWidth / ratio, model.videoDuration / svgWidth )
            else
                ( svgWidth * ratio, svgWidth, model.audioDuration / svgWidth )

        videoLineY =
            markerBaseHeight + (lineHeight // 2)

        audioLineY =
            videoLineY + lineHeight + lineMargin

        aspectRatio =
            model.videoSize.width / model.videoSize.height

        maxWidth =
            toFloat model.windowSize.width

        maxHeight =
            toFloat (model.windowSize.height - controlsHeight)

        heightIfMaxWidth =
            maxWidth / aspectRatio

        clampedWidth =
            if heightIfMaxWidth <= maxHeight then
                maxWidth
            else
                maxHeight * aspectRatio
    in
    div []
        [ div [ class "VideoWrapper" ]
            [ video
                ([ src "/sommaren_video.mp4"
                 , width (truncate clampedWidth)
                 , property "muted" (Encode.bool True)
                 , on "loadedmetadata" (decodeVideoMetaData VideoMetaData)
                 , on "timeupdate" (decodeMediaCurrentTime VideoCurrentTime)
                 ]
                    ++ playEvents VideoPlayState
                )
                []
            ]
        , audio
            ([ src "/sommaren_audio.aac"
             , on "loadedmetadata" (decodeAudioMetaData AudioMetaData)
             , on "timeupdate" (decodeMediaCurrentTime AudioCurrentTime)
             ]
                ++ playEvents AudioPlayState
            )
            []
        , div []
            [ button
                [ type_ "button"
                , onClick <|
                    VideoPlayState (not model.videoPlaying)
                ]
                [ text <|
                    if model.videoPlaying then
                        "Pause video"
                    else
                        "Play video"
                ]
            ]
        , svg [ viewBox viewBoxString ]
            [ line
                [ x1 "0"
                , y1 (toString videoLineY)
                , x2 (toString videoLineWidth)
                , y2 (toString videoLineY)
                , strokeWidth (toString lineHeight)
                ]
                []
            , line
                [ x1 "0"
                , y1 (toString audioLineY)
                , x2 (toString audioLineWidth)
                , y2 (toString audioLineY)
                , strokeWidth (toString lineHeight)
                ]
                []
            , Svg.text_
                [ x (toString videoLineWidth)
                , y (toString videoLineY)
                , dy "-0.5em"
                , textAnchor "end"
                ]
                [ Svg.text (formatDuration model.videoDuration)
                ]
            , Svg.text_
                [ x (toString audioLineWidth)
                , y (toString (audioLineY + lineHeight))
                , dy "0.5em"
                , textAnchor "end"
                ]
                [ Svg.text (formatDuration model.audioDuration)
                ]
            , circle
                [ cx (toString (model.videoCurrentTime / scale))
                , cy (toString videoLineY)
                , r (toString (lineHeight // 2))
                ]
                []
            , circle
                [ cx (toString (model.audioCurrentTime / scale))
                , cy (toString audioLineY)
                , r (toString (lineHeight // 2))
                ]
                []
            ]
        , div []
            [ button
                [ type_ "button"
                , onClick <|
                    AudioPlayState (not model.audioPlaying)
                ]
                [ text <|
                    if model.audioPlaying then
                        "Pause audio"
                    else
                        "Play audio"
                ]
            ]
        ]


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
