module View.Graphics exposing (view)

import Data.DomId as DomId
import Data.Model exposing (DragBar, MediaPlayerId(Audio, Video), Model, Msg(DragStart))
import Html exposing (Html)
import Html.Attributes
import Html.Custom exposing (none)
import Html.Events.Custom exposing (MouseDownDetails, onMouseDown)
import ModelUtils
import Svg
import Svg.Attributes as SvgAttr
import Svg.Attributes.Custom


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
                0
            else
                number / scale

        videoY =
            0

        audioY =
            videoY + progressBarHeight + progressBarSpacing

        ( audioCurrentTime, videoCurrentTime ) =
            ModelUtils.getCurrentTimes model

        videoProgressBarDetails =
            { maxValue = toScale model.video.duration
            , currentValue = toScale videoCurrentTime
            , x = progressBarX
            , y = videoY
            , onDragStart = DragStart Video
            }

        audioProgressBarDetails =
            { maxValue = toScale model.audio.duration
            , currentValue = toScale audioCurrentTime
            , x = progressBarX
            , y = audioY
            , onDragStart = DragStart Audio
            }

        points =
            model.points
                |> List.filter
                    (\{ audioTime, videoTime } ->
                        (audioTime >= 0 && audioTime <= model.audio.duration)
                            && (videoTime >= 0 && videoTime <= model.video.duration)
                    )
                |> List.map
                    (\{ audioTime, videoTime } ->
                        { x1 = toScale videoTime
                        , x2 = toScale audioTime
                        }
                    )
    in
    Html.div
        [ DomId.toHtml DomId.GraphicsArea
        , Html.Attributes.class "Graphics"
        , Html.Attributes.style [ ( "height", toString svgHeight ++ "px" ) ]
        ]
        [ Svg.svg
            [ SvgAttr.viewBox viewBoxString
            , SvgAttr.class "Graphics-svg"
            ]
            [ progressBarBackground videoProgressBarDetails
            , progressBarBackground audioProgressBarDetails
            , Svg.g [] <|
                List.map
                    (\{ x1, x2 } ->
                        Svg.polyline
                            [ Svg.Attributes.Custom.points
                                [ ( x1, videoY )
                                , ( x1, videoY + progressBarHeight )
                                , ( x2, audioY )
                                , ( x2, audioY + progressBarHeight )
                                ]
                            , SvgAttr.class "Point"
                            ]
                            []
                    )
                    points
            , progressBarForeground videoProgressBarDetails
            , progressBarForeground audioProgressBarDetails
            ]
        ]


type alias ProgressBarDetails msg =
    { maxValue : Float
    , currentValue : Float
    , x : Float
    , y : Float
    , onDragStart : DragBar -> MouseDownDetails -> msg
    }


progressBarBackground : ProgressBarDetails msg -> Html msg
progressBarBackground { maxValue, currentValue, x, y } =
    let
        width =
            maxValue

        progressWidth =
            currentValue
    in
    Svg.g [ SvgAttr.class "ProgressBarBackground" ]
        [ Svg.rect
            [ SvgAttr.x (toString x)
            , SvgAttr.y (toString y)
            , SvgAttr.width (toString width)
            , SvgAttr.height (toString progressBarHeight)
            , SvgAttr.class "ProgressBarBackground-background"
            ]
            []
        , Svg.rect
            [ SvgAttr.x (toString x)
            , SvgAttr.y (toString y)
            , SvgAttr.width (toString progressWidth)
            , SvgAttr.height (toString progressBarHeight)
            , SvgAttr.class "ProgressBarBackground-progress"
            ]
            []
        ]


progressBarForeground : ProgressBarDetails msg -> Html msg
progressBarForeground { maxValue, currentValue, x, y, onDragStart } =
    let
        width =
            maxValue

        progressWidth =
            currentValue
    in
    if width <= 0 then
        none
    else
        Svg.g [ SvgAttr.class "ProgressBarForeground" ]
            [ Svg.line
                [ SvgAttr.x1 (toString progressWidth)
                , SvgAttr.y1 (toString y)
                , SvgAttr.x2 (toString progressWidth)
                , SvgAttr.y2 (toString (y + progressBarHeight))
                , SvgAttr.class "ProgressBarForeground-current"
                ]
                []
            , Svg.rect
                [ SvgAttr.x (toString x)
                , SvgAttr.y (toString (y - progressBarMouseAreaExtra / 2))
                , SvgAttr.width (toString width)
                , SvgAttr.height (toString (progressBarHeight + progressBarMouseAreaExtra))
                , SvgAttr.class "ProgressBarForeground-mouseArea"
                , onMouseDown <|
                    onDragStart
                        { x = x
                        , width = width
                        }
                ]
                []
            ]
