module View.Media exposing (view)

import Data.DomId as DomId
import Data.Model exposing (..)
import Html exposing (Attribute, Html, audio, p, text, video)
import Html.Attributes exposing (class, src, width)
import Html.Attributes.Custom exposing (muted)
import Html.Custom exposing (none)
import Html.Events exposing (on)
import Html.Events.Custom exposing (onAudioMetaData, onError, onTimeUpdate, onVideoMetaData)
import Json.Decode as Decode exposing (Decoder)


view : Model -> List (Html Msg)
view model =
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
    [ case model.video.url of
        Just url ->
            video
                ([ src url
                 , width (truncate clampedWidth)
                 , muted True
                 , onError (MediaErrorMsg Video)
                 , onVideoMetaData (MetaData Video)
                 , onTimeUpdate (CurrentTime Video)
                 , DomId.toHtml DomId.Video
                 ]
                    ++ playEvents Video
                )
                []

        Nothing ->
            p [ class "MegaMessage" ] [ text "Drag and drop files or use the buttons below to open a video file, the corresponding audio file, and optionally a points file." ]
    , case model.audio.url of
        Just url ->
            audio
                ([ src url
                 , onError (MediaErrorMsg Audio)
                 , onAudioMetaData (MetaData Audio)
                 , onTimeUpdate (CurrentTime Audio)
                 , DomId.toHtml DomId.Audio
                 ]
                    ++ playEvents Audio
                )
                []

        Nothing ->
            none
    ]


playEvents : MediaPlayerId -> List (Attribute Msg)
playEvents id =
    let
        decoder =
            decodePlayState id
    in
    [ on "abort" decoder
    , on "ended" decoder
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
                if paused then
                    ExternalPause id
                else
                    ExternalPlay id
            )
