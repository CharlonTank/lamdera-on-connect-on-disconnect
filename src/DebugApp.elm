module DebugApp exposing (backend)

import Http
import Json.Encode
import Lamdera exposing (ClientId, SessionId)


backend :
    backendMsg
    -> String
    ->
        { init : ( backendModel, Cmd backendMsg )
        , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
        , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
        , subscriptions : backendModel -> Sub backendMsg
        }
    ->
        { init : ( backendModel, Cmd backendMsg )
        , update : backendMsg -> backendModel -> ( backendModel, Cmd backendMsg )
        , updateFromFrontend : SessionId -> ClientId -> toBackend -> backendModel -> ( backendModel, Cmd backendMsg )
        , subscriptions : backendModel -> Sub backendMsg
        }
backend backendNoOp sessionName { init, update, updateFromFrontend, subscriptions } =
    { init =
        let
            ( model, cmd ) =
                init
        in
        ( model
        , Cmd.batch
            [ cmd
            , sendToViewer
                backendNoOp
                (Init { sessionName = sessionName, model = Debug.toString model })
            ]
        )
    , update =
        \msg model ->
            let
                ( newModel, cmd ) =
                    update msg model
            in
            ( newModel
            , Cmd.batch
                [ cmd
                , if backendNoOp == msg then
                    Cmd.none

                  else
                    sendToViewer
                        backendNoOp
                        (Update
                            { sessionName = sessionName
                            , msg = Debug.toString msg
                            , newModel = Debug.toString newModel
                            }
                        )
                ]
            )
    , updateFromFrontend =
        \sessionId clientId msg model ->
            let
                ( newModel, cmd ) =
                    updateFromFrontend sessionId clientId msg model
            in
            ( newModel
            , Cmd.batch
                [ cmd
                , sendToViewer
                    backendNoOp
                    (UpdateFromFrontend
                        { sessionName = sessionName
                        , msg = Debug.toString msg
                        , newModel = Debug.toString newModel
                        , sessionId = sessionId
                        , clientId = clientId
                        }
                    )
                ]
            )
    , subscriptions = subscriptions
    }


type DataType
    = Init { sessionName : String, model : String }
    | Update { sessionName : String, msg : String, newModel : String }
    | UpdateFromFrontend { sessionName : String, msg : String, newModel : String, sessionId : String, clientId : String }


sendToViewer : msg -> DataType -> Cmd msg
sendToViewer backendNoOp data =
    Http.post
        { url = "http://localhost:8001/https://backend-debugger.lamdera.app/_r/data"
        , body = Http.jsonBody (encodeDataType data)
        , expect = Http.expectWhatever (\_ -> backendNoOp)
        }


encodeDataType : DataType -> Json.Encode.Value
encodeDataType data =
    Json.Encode.list
        identity
        (case data of
            Init { sessionName, model } ->
                [ Json.Encode.int 0
                , Json.Encode.string sessionName
                , Json.Encode.string model
                , Json.Encode.null
                ]

            Update { sessionName, msg, newModel } ->
                [ Json.Encode.int 1
                , Json.Encode.string sessionName
                , Json.Encode.string msg
                , Json.Encode.string newModel
                , Json.Encode.null
                ]

            UpdateFromFrontend { sessionName, msg, newModel, sessionId, clientId } ->
                [ Json.Encode.int 2
                , Json.Encode.string sessionName
                , Json.Encode.string msg
                , Json.Encode.string newModel
                , Json.Encode.string sessionId
                , Json.Encode.string clientId
                , Json.Encode.null
                ]
        )
