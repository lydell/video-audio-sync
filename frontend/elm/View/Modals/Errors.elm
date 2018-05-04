module View.Modals.Errors exposing (view)

import Data.Error as Error exposing (Error)
import Data.File as File
import Html exposing (Html, code, li, p, strong, text, ul)
import Utils
import View.Modal as Modal


view : msg -> List Error -> Html msg
view msg errors =
    Modal.alert msg (content errors)


content : List Error -> List (Html msg)
content errors =
    [ p []
        [ strong []
            [ text <|
                case errors of
                    [] ->
                        "No errors!"

                    [ _ ] ->
                        "There was an error with your file."

                    _ ->
                        "There were some errors with your files."
            ]
        ]
    , ul [] <|
        List.map (viewError >> li []) errors
    ]


viewError : Error -> List (Html msg)
viewError error =
    case error of
        Error.InvalidFile { name, expectedFileTypes } ->
            let
                expected =
                    case expectedFileTypes of
                        [] ->
                            "nothing"

                        _ ->
                            Utils.humanList "or"
                                (List.map File.fileTypeToHumanString expectedFileTypes)
            in
            [ code [] [ text name ]
            , text <| " is invalid. Expected " ++ expected ++ "."
            ]

        Error.ErroredFile { name, fileType } ->
            [ text "Failed to read "
            , code [] [ text name ]
            , text <| " as " ++ File.fileTypeToHumanString fileType ++ "."
            ]

        Error.Media { name, fileType } ->
            [ text "Failed to play "
            , code [] [ text name ]
            , text <|
                " as "
                    ++ File.fileTypeToHumanString fileType
                    ++ ". The file is either unsupported, broken or invalid."
            ]

        Error.InvalidPoints { name, message } ->
            [ p []
                [ text "Failed to parse "
                , code [] [ text name ]
                , text <| " as " ++ File.fileTypeToHumanString File.JsonFile ++ ". "
                ]
            , p [] [ code [] [ text (Utils.truncateJsonDecodeErrorMessage message) ] ]
            ]
