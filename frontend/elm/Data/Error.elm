module Data.Error exposing (Error(..))

import Data.File exposing (ErroredFileDetails, InvalidFileDetails)


type Error
    = InvalidFile InvalidFileDetails
    | ErroredFile ErroredFileDetails
    | Media ErroredFileDetails
    | InvalidPoints InvalidPointsDetails


type alias InvalidPointsDetails =
    { name : String
    , message : String
    }
