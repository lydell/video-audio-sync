module View exposing (view)

import DomId
import Html exposing (Attribute, Html, audio, button, code, div, li, p, span, text, ul, video)
import Html.Attributes exposing (attribute, class, classList, disabled, src, style, title, type_, width)
import Html.Attributes.Custom exposing (muted)
import Html.Custom exposing (none)
import Html.Events exposing (on, onClick)
import Html.Events.Custom exposing (MetaDataDetails, MouseDownDetails, onAudioMetaData, onClickWithButton, onError, onMouseDown, onTimeUpdate, onVideoMetaData, preventContextMenu)
import Json.Decode as Decode exposing (Decoder)
import MediaPlayer exposing (MediaPlayer, PlayState(Paused, Playing))
import Points
import Ports
import Svg
import Svg.Attributes as Svg
import Time exposing (Time)
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


jumpActionsForward : List JumpAction
jumpActionsForward =
    [ { timeOffset = 100 * Time.millisecond
      , label = "0.1s"
      }
    , { timeOffset = 1 * Time.second
      , label = "1s"
      }
    , { timeOffset = 1 * Time.minute
      , label = "1m"
      }
    , { timeOffset = 10 * Time.minute
      , label = "10m"
      }
    ]


jumpActionsBackward : List JumpAction
jumpActionsBackward =
    jumpActionsForward
        |> List.reverse
        |> List.map
            (\jumpAction ->
                { jumpAction | timeOffset = negate jumpAction.timeOffset }
            )


view : Model -> Html Msg
view model =
    div [ class "Layout" ]
        [ viewMedia model
        , viewControls model
        , viewModals model
        , if model.isDraggingFile then
            fileDragOverlay
          else
            none
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
                     , class "Layout-video"
                     ]
                        ++ playEvents Video
                    )
                    []

            Nothing ->
                p [ class "Layout-videoMessage" ] [ text "Drag and drop files or use the buttons below to open a video file, the corresponding audio file, and optionally a points file." ]
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
                0
            else
                number / scale

        videoY =
            0

        audioY =
            videoY + progressBarHeight + progressBarSpacing

        ( audioCurrentTime, videoCurrentTime ) =
            Utils.getCurrentTimes model

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
    div
        [ DomId.toHtml DomId.GraphicsArea
        , class "Graphics"
        , style [ ( "height", toString svgHeight ++ "px" ) ]
        ]
        [ Svg.svg
            [ Svg.viewBox viewBoxString
            , Svg.class "Graphics-svg"
            ]
            [ progressBarBackground videoProgressBarDetails
            , progressBarBackground audioProgressBarDetails
            , Svg.g [] <|
                List.map
                    (\{ x1, x2 } ->
                        Svg.polyline
                            [ Svg.points
                                (toPoints
                                    [ ( x1, videoY )
                                    , ( x1, videoY + progressBarHeight )
                                    , ( x2, audioY )
                                    , ( x2, audioY + progressBarHeight )
                                    ]
                                )
                            , Svg.class "Point"
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
    Svg.g [ Svg.class "ProgressBarBackground" ]
        [ Svg.rect
            [ Svg.x (toString x)
            , Svg.y (toString y)
            , Svg.width (toString width)
            , Svg.height (toString progressBarHeight)
            , Svg.class "ProgressBarBackground-background"
            ]
            []
        , Svg.rect
            [ Svg.x (toString x)
            , Svg.y (toString y)
            , Svg.width (toString progressWidth)
            , Svg.height (toString progressBarHeight)
            , Svg.class "ProgressBarBackground-progress"
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
        Svg.g [ Svg.class "ProgressBarForeground" ]
            [ Svg.line
                [ Svg.x1 (toString progressWidth)
                , Svg.y1 (toString y)
                , Svg.x2 (toString progressWidth)
                , Svg.y2 (toString (y + progressBarHeight))
                , Svg.class "ProgressBarForeground-current"
                ]
                []
            , Svg.rect
                [ Svg.x (toString x)
                , Svg.y (toString (y - progressBarMouseAreaExtra / 2))
                , Svg.width (toString width)
                , Svg.height (toString (progressBarHeight + progressBarMouseAreaExtra))
                , Svg.class "ProgressBarForeground-mouseArea"
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
        hasMedia =
            MediaPlayer.hasMedia mediaPlayer

        backwardEnabled =
            hasMedia && mediaPlayer.currentTime > 0

        forwardEnabled =
            hasMedia && mediaPlayer.currentTime < mediaPlayer.duration

        ( name, icon ) =
            case id of
                Audio ->
                    ( "Audio", Icon "file-audio" )

                Video ->
                    ( "Video", Icon "file-video" )

        ( playPauseTitle, playPauseIcon ) =
            case ( mediaPlayer.playState, loopState ) of
                ( Playing, Normal ) ->
                    ( name ++ " is playing. Click to pause."
                    , Icon "pause"
                    )

                ( Playing, Looping _ ) ->
                    ( "Looping. Click to pause."
                    , CustomIcon "pause-circle" "fa-1.25"
                    )

                ( Paused, Normal ) ->
                    ( name ++ " is paused. Click to play."
                    , Icon "play"
                    )

                ( Paused, Looping _ ) ->
                    ( "Paused. Click to loop."
                    , CustomIcon "play-circle" "fa-1.25"
                    )
    in
    toolbar
        [ buttonGroup
            [ { emptyButton
                | icon = icon
                , title = "Open " ++ String.toLower name
                , attributes =
                    [ onClick (OpenMedia id)
                    , class
                        (if hasMedia then
                            ""
                         else
                            "is-animated"
                        )
                    ]
              }
            ]
        , buttonGroup
            [ { emptyButton
                | icon = playPauseIcon
                , title = playPauseTitle
                , pressed =
                    case mediaPlayer.playState of
                        Playing ->
                            True

                        Paused ->
                            False
                , attributes =
                    [ disabled (not hasMedia) ]
                        ++ (onClickWithButton <|
                                case mediaPlayer.playState of
                                    Playing ->
                                        Pause id

                                    Paused ->
                                        Play id
                           )
              }
            ]
        , buttonGroup <|
            List.map (buttonDetailsFromJumpAction id backwardEnabled) jumpActionsBackward
        , buttonGroup <|
            List.map (buttonDetailsFromJumpAction id forwardEnabled) jumpActionsForward
        , buttonGroup
            [ { emptyButton
                | icon = Icon "step-backward"
                , title = "Previous point"
                , attributes =
                    [ disabled (not backwardEnabled) ]
                        ++ onClickWithButton (JumpByPoint id Backward)
              }
            , { emptyButton
                | icon = Icon "step-forward"
                , title = "Next point"
                , attributes =
                    [ disabled (not forwardEnabled) ]
                        ++ onClickWithButton (JumpByPoint id Forward)
              }
            ]
        , if mediaPlayer.duration > 0 then
            p []
                [ text <|
                    Utils.formatDuration mediaPlayer.currentTime
                        ++ " / "
                        ++ Utils.formatDuration mediaPlayer.duration
                ]
          else
            none
        ]


buttonDetailsFromJumpAction :
    MediaPlayerId
    -> Bool
    -> JumpAction
    -> ButtonDetails Msg
buttonDetailsFromJumpAction id enabled jumpAction =
    let
        base =
            { emptyButton
                | attributes =
                    [ disabled (not enabled) ]
                        ++ onClickWithButton (JumpByTime id jumpAction.timeOffset)
            }
    in
    if jumpAction.timeOffset < 0 then
        { base
            | icon = Icon "backward"
            , title = "Jump backward: " ++ jumpAction.label
            , label = RightLabel jumpAction.label
        }
    else
        { base
            | icon = Icon "forward"
            , title = "Jump forward: " ++ jumpAction.label
            , label = LeftLabel jumpAction.label
        }


generalToolbar : Model -> Html Msg
generalToolbar model =
    let
        hasAudio =
            MediaPlayer.hasMedia model.audio

        hasVideo =
            MediaPlayer.hasMedia model.video

        ( audioCurrentTime, videoCurrentTime ) =
            Utils.getCurrentTimes model

        potentialNewPoint =
            { audioTime = audioCurrentTime
            , videoTime = videoCurrentTime
            }

        selectedPoint =
            Utils.getSelectedPoint potentialNewPoint model.points

        canAddPoint =
            Utils.canAddPoint model.points potentialNewPoint

        warnings =
            Points.validate model.points

        numWarnings =
            List.length warnings
    in
    toolbar
        [ buttonGroup
            [ { emptyButton
                | icon = Icon "file-alt"
                , title = "Open points"
                , attributes =
                    [ onClick OpenPoints
                    , class
                        (if hasAudio || hasVideo then
                            ""
                         else
                            "is-animated"
                        )
                    ]
              }
            ]
        , buttonGroup
            [ { emptyButton
                | icon = Icon "sync-alt"
                , title =
                    case model.loopState of
                        Normal ->
                            "Video and audio play normally. Click to loop."

                        Looping _ ->
                            "Video and audio loop around their current positions. Click to play normally."
                , pressed =
                    case model.loopState of
                        Normal ->
                            False

                        Looping _ ->
                            True
                , attributes =
                    [ onClick <|
                        case model.loopState of
                            Normal ->
                                GoLooping

                            Looping _ ->
                                GoNormal
                    , disabled (not (hasAudio && hasVideo))
                    ]
              }
            ]
        , buttonGroup
            [ case selectedPoint of
                Just point ->
                    { emptyButton
                        | icon = Icon "minus"
                        , title = "Remove point"
                        , attributes =
                            [ onClick (RemovePoint point)
                            , disabled (not (hasAudio && hasVideo))
                            ]
                    }

                Nothing ->
                    { emptyButton
                        | icon = Icon "plus"
                        , title = "Add point"
                        , attributes =
                            [ onClick (AddPoint potentialNewPoint)
                            , disabled (not (hasAudio && hasVideo && canAddPoint))
                            ]
                    }
            , { emptyButton
                | icon = Icon "exclamation-triangle "
                , title =
                    case numWarnings of
                        0 ->
                            "No warnings!"

                        1 ->
                            "1 warning"

                        _ ->
                            toString numWarnings ++ " warnings"
                , badge =
                    if numWarnings == 0 then
                        Nothing
                    else
                        Just <| toString numWarnings
                , attributes =
                    [ onClick OpenPointsWarningsModal
                    , disabled (numWarnings == 0)
                    ]
              }
            ]
        , buttonGroup
            [ { emptyButton
                | icon = Icon "save"
                , title = "Save points"
                , attributes =
                    [ onClick Save
                    , disabled (model.points == [])
                    ]
              }
            , { emptyButton
                | icon = Icon "trash"
                , title = "Remove all points"
                , attributes =
                    [ onClick ConfirmRemoveAllPoints
                    , disabled (model.points == [])
                    ]
              }
            , { emptyButton
                | icon = Icon "copy"
                , title = "Open multiple files in one go"
                , attributes =
                    [ onClick OpenMultiple
                    , class
                        (if hasAudio || hasVideo then
                            ""
                         else
                            "is-animated"
                        )
                    ]
              }
            ]
        ]


toolbar : List (Html msg) -> Html msg
toolbar children =
    div [ class "Toolbar" ] children


type alias ButtonDetails msg =
    { icon : Icon
    , title : String
    , label : ButtonLabel
    , badge : Maybe String
    , pressed : Bool
    , attributes : List (Attribute msg)
    }


type ButtonLabel
    = NoLabel
    | LeftLabel String
    | RightLabel String


emptyButton : ButtonDetails msg
emptyButton =
    { icon = Icon ""
    , title = ""
    , label = NoLabel
    , badge = Nothing
    , pressed = False
    , attributes = []
    }


buttonGroup : List (ButtonDetails msg) -> Html msg
buttonGroup buttons =
    div [ class "ButtonGroup" ] (List.map buttonGroupButton buttons)


buttonGroupButton : ButtonDetails msg -> Html msg
buttonGroupButton buttonDetails =
    let
        label labelText =
            span
                [ attribute "aria-hidden" "true"
                , class "ButtonGroup-buttonLabel"
                ]
                [ text labelText ]

        icon =
            fontawesome buttonDetails.icon
    in
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
        [ div [ class "ButtonGroup-buttonInner" ] <|
            case buttonDetails.label of
                NoLabel ->
                    [ icon ]

                LeftLabel labelText ->
                    [ label labelText, icon ]

                RightLabel labelText ->
                    [ icon, label labelText ]
        , case buttonDetails.badge of
            Just badgeText ->
                span [ class "ButtonGroup-buttonBadge" ] [ text badgeText ]

            Nothing ->
                none
        ]


type Icon
    = Icon String
    | CustomIcon String String


fontawesome : Icon -> Html msg
fontawesome icon =
    let
        ( name, extraClass ) =
            case icon of
                Icon name ->
                    ( name, "" )

                CustomIcon name extraClass ->
                    ( name, extraClass )
    in
    span
        [ attribute "aria-hidden" "true"
        , class ("fas fa-" ++ name ++ " " ++ extraClass)
        ]
        []


fileDragOverlay : Html msg
fileDragOverlay =
    div [ class "FileDragOverlay" ]
        [ fontawesome (CustomIcon "copy" "fa-4x")
        , p []
            [ text "Drop video, audio and/or points" ]
        ]


modal : msg -> List (Html msg) -> List (Html msg) -> Html msg
modal msg buttons children =
    div [ class "Modal" ]
        [ div [ class "Modal-backdrop", onClick msg ] []
        , div [ class "Modal-content" ]
            [ div [] children
            , div [] buttons
            ]
        ]


modalButton : msg -> String -> Html msg
modalButton msg label =
    button [ type_ "button", class "Modal-button", onClick msg ]
        [ text label
        ]


alertModal : msg -> List (Html msg) -> Html msg
alertModal msg children =
    modal
        msg
        [ modalButton msg "Close"
        ]
        children


confirmModal :
    { cancel : ( msg, String ), confirm : ( msg, String ) }
    -> List (Html msg)
    -> Html msg
confirmModal { cancel, confirm } children =
    modal
        (Tuple.first cancel)
        [ uncurry modalButton cancel
        , uncurry modalButton confirm
        ]
        children


viewModals : Model -> Html Msg
viewModals model =
    div []
        [ if model.pointsWarningsModalOpen then
            let
                warnings =
                    Points.validate model.points
            in
            alertModal ClosePointsWarningsModal
                [ p []
                    [ text <|
                        "The syncing program can handle slowing down audio down to "
                            ++ toString Points.tempoMin
                            ++ " times or speeding up audio up to "
                            ++ toString Points.tempoMax
                            ++ " times. The audio between some points would need to be slowed down or sped up more than that."
                    ]
                , ul [] <|
                    List.map
                        (\( index, tempo ) ->
                            let
                                start =
                                    if index == 0 then
                                        "From the start to point 1"
                                    else
                                        "Between point " ++ toString (index - 1) ++ " and point " ++ toString index
                            in
                            li [] [ text <| start ++ ": " ++ toString tempo ++ " times." ]
                        )
                        warnings
                ]
          else
            none
        , if model.confirmRemoveAllPointsModalOpen then
            confirmModal
                { cancel = ( CloseRemoveAllPoints, "No, keep them!" )
                , confirm = ( RemoveAllPoints, "Yes, remove them!" )
                }
                [ p [] [ text "This removes all points you have added. Are you sure?" ]
                ]
          else
            none
        , case model.confirmOpenPoints of
            Just { name, points } ->
                confirmModal
                    { cancel = ( CloseOpenPoints, "No, keep my current points!" )
                    , confirm = ( OpenConfirmedPoints points, "Yes, replace them!" )
                    }
                    [ p []
                        [ text "This replaces all points you have added with the ones in "
                        , code [] [ text name ]
                        , text ". Are you sure?"
                        ]
                    ]

            Nothing ->
                none
        , case model.errors of
            [] ->
                none

            errors ->
                alertModal CloseErrorModal
                    [ ul [] (List.map viewError errors)
                    ]
        ]


viewError : Error -> Html msg
viewError error =
    case error of
        InvalidFileError { name, expectedFileTypes } ->
            let
                expected =
                    case expectedFileTypes of
                        [] ->
                            "nothing"

                        _ ->
                            humanList "or" (List.map fileTypeToString expectedFileTypes)
            in
            p []
                [ code [] [ text name ]
                , text <| " is invalid. Expected " ++ expected ++ "."
                ]

        ErroredFileError { name, fileType } ->
            p []
                [ text "Failed to read "
                , code [] [ text name ]
                , text <| " as " ++ fileTypeToString fileType ++ "."
                ]

        MediaError { name, fileType } ->
            p []
                [ text "Failed to play "
                , code [] [ text name ]
                , text <|
                    " as "
                        ++ fileTypeToString fileType
                        ++ ". The file is either unsupported, broken or invalid."
                ]

        Types.InvalidPointsError { name, message } ->
            p []
                [ text "Failed to parse "
                , code [] [ text name ]
                , text <| " as " ++ fileTypeToString Ports.JsonFile ++ ". "
                , code [] [ text message ]
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
                case paused of
                    True ->
                        ExternalPause id

                    False ->
                        ExternalPlay id
            )


toPoints : List ( number, number ) -> String
toPoints coords =
    coords
        |> List.map (\( x, y ) -> toString x ++ "," ++ toString y)
        |> String.join " "


humanList : String -> List String -> String
humanList joinWord strings =
    case List.reverse strings of
        [] ->
            ""

        [ string ] ->
            string

        last :: rest ->
            let
                start =
                    rest
                        |> List.reverse
                        |> String.join ", "
            in
            start ++ " " ++ joinWord ++ " " ++ last


fileTypeToString : Ports.FileType -> String
fileTypeToString fileType =
    case fileType of
        Ports.AudioFile ->
            "audio"

        Ports.VideoFile ->
            "video"

        Ports.JsonFile ->
            "JSON"
