module Points exposing (decoder, encode)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Time exposing (Time)
import Types exposing (..)


type alias TempoPoint =
    ( Time, Float )


encode : List Point -> Encode.Value
encode points =
    Encode.object
        [ ( "points", encodePoints points )
        ]


encodePoints : List Point -> Encode.Value
encodePoints points =
    points
        |> toTempoPoints
        |> List.map encodeTempoPoint
        |> Encode.list


toTempoPoints : List Point -> List TempoPoint
toTempoPoints points =
    points
        |> List.sortBy .audioTime
        |> List.foldl
            (\point ( lastPoint, result ) ->
                let
                    audioDuration =
                        point.audioTime - lastPoint.audioTime

                    videoDuration =
                        point.videoTime - lastPoint.videoTime

                    tempoPoint =
                        ( audioDuration
                        , audioDuration / videoDuration
                        )
                in
                ( point, tempoPoint :: result )
            )
            ( { audioTime = 0, videoTime = 0 }, [] )
        |> Tuple.second
        |> List.reverse


encodeTempoPoint : TempoPoint -> Encode.Value
encodeTempoPoint ( audioDuration, tempo ) =
    Encode.list
        [ Encode.float audioDuration
        , Encode.float tempo
        ]


decoder : Decoder (List Point)
decoder =
    Decode.field "points" tempoPointsDecoder


tempoPointsDecoder : Decoder (List Point)
tempoPointsDecoder =
    Decode.list tempoPointDecoder
        |> Decode.map fromTempoPoints


tempoPointDecoder : Decoder TempoPoint
tempoPointDecoder =
    Decode.map2 (,)
        (Decode.index 0 Decode.float)
        (Decode.index 1 Decode.float)


fromTempoPoints : List TempoPoint -> List Point
fromTempoPoints tempoPoints =
    tempoPoints
        |> List.foldl
            (\( audioDuration, tempo ) ( lastPoint, result ) ->
                let
                    audioTime =
                        lastPoint.audioTime + audioDuration

                    videoTime =
                        lastPoint.videoTime + audioDuration / tempo

                    point =
                        { audioTime = audioTime
                        , videoTime = videoTime
                        }
                in
                ( point, point :: result )
            )
            ( { audioTime = 0, videoTime = 0 }, [] )
        |> Tuple.second
        |> List.reverse
