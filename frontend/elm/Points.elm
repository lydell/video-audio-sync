module Points exposing (Direction(..), Point, canAddPoint, decoder, encode, getClosestPoint, getSelectedPoint, tempoMax, tempoMin, validate)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import List.Extra
import Time exposing (Time)


tempoMin : Float
tempoMin =
    0.5


tempoMax : Float
tempoMax =
    2


maxPointOffset : Time
maxPointOffset =
    0.05 * Time.second


type alias TempoPoint =
    ( Time, Float )


type alias Point =
    { audioTime : Time
    , videoTime : Time
    }


type Direction
    = Forward
    | Backward


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


validate : List Point -> List ( Int, Float )
validate points =
    points
        |> toTempoPoints
        |> List.indexedMap (,)
        |> List.filterMap
            (\( index, ( _, tempo ) ) ->
                if tempo < tempoMin || tempo > tempoMax then
                    Just ( index, tempo )
                else
                    Nothing
            )


getSelectedPoint :
    { audioTime : Time, videoTime : Time }
    -> List Point
    -> Maybe Point
getSelectedPoint { audioTime, videoTime } points =
    points
        |> List.map
            (\point ->
                let
                    audioDistance =
                        abs (point.audioTime - audioTime)

                    videoDistance =
                        abs (point.videoTime - videoTime)
                in
                ( audioDistance, videoDistance, point )
            )
        |> List.filter
            (\( audioDistance, videoDistance, _ ) ->
                (audioDistance < maxPointOffset)
                    && (videoDistance < maxPointOffset)
            )
        |> List.Extra.minimumBy
            (\( audioDistance, videoDistance, _ ) ->
                audioDistance + videoDistance
            )
        |> Maybe.map (\( _, _, point ) -> point)


getClosestPoint :
    (Point -> Time)
    -> Direction
    -> Time
    -> List Point
    -> Maybe Point
getClosestPoint getTime direction time points =
    points
        |> List.map (\point -> ( getTime point - time, point ))
        |> List.filter
            (\( distance, _ ) ->
                case direction of
                    Forward ->
                        distance >= maxPointOffset

                    Backward ->
                        distance <= -maxPointOffset
            )
        |> List.Extra.minimumBy (Tuple.first >> abs)
        |> Maybe.map Tuple.second


canAddPoint : List Point -> Point -> Bool
canAddPoint points potentialNewPoint =
    let
        hasSelected getTime =
            List.any
                (\point ->
                    let
                        distance =
                            abs (getTime point - getTime potentialNewPoint)
                    in
                    distance <= maxPointOffset
                )
                points

        countBefore getTime =
            points
                |> List.filter
                    (\point -> getTime point < getTime potentialNewPoint)
                |> List.length
    in
    (potentialNewPoint.audioTime > 0)
        && (potentialNewPoint.videoTime > 0)
        && not (hasSelected .audioTime)
        && not (hasSelected .videoTime)
        && (countBefore .audioTime == countBefore .videoTime)
