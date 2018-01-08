module View exposing (view)

import Html exposing (Html, audio, button, div, p, span, text, video)
import Html.Attributes exposing (attribute, class, property, src, title, type_, width)
import Html.Events exposing (on, onClick)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
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


svgHeight : Int
svgHeight =
    (lineHeight * 2) + lineBetween


controlsHeight : Int
controlsHeight =
    svgHeight
        + (41 * 2)



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

        maxLineWidth =
            svgWidth - toFloat lineMargin * 2

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

        videoLineY =
            0

        audioLineY =
            videoLineY + lineHeight + lineBetween

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
        , div [ class "Toolbar" ]
            [ fontawesome "video-camera"
            , button
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
        , Svg.svg [ Svg.viewBox viewBoxString, Svg.class "Progress" ]
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
                , Svg.width (toString (model.videoCurrentTime / scale))
                , Svg.height (toString lineHeight)
                , Svg.class "Progress-elapsed"
                ]
                []
            , Svg.rect
                [ Svg.x (toString lineMargin)
                , Svg.y (toString audioLineY)
                , Svg.width (toString (model.audioCurrentTime / scale))
                , Svg.height (toString lineHeight)
                , Svg.class "Progress-elapsed"
                ]
                []
            ]
        , div [ class "Toolbar" ]
            [ fontawesome "volume-up"
            , button
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
