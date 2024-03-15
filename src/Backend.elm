module Backend exposing (..)

import DebugApp
import Html
import Lamdera exposing (ClientId, SessionId)
import Types exposing (..)


type alias Model =
    BackendModel


app =
    DebugApp.backend
        NoOpBackendMsg
        "e465a26049dfca11"
        { init = init
        , update = update
        , updateFromFrontend = updateFromFrontend
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub BackendMsg
subscriptions _ =
    Sub.batch
        [ Lamdera.onDisconnect OnDisconnect
        , Lamdera.onConnect OnConnect
        ]


init : ( Model, Cmd BackendMsg )
init =
    ( { message = "Hello!" }
    , Cmd.none
    )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        NoOpBackendMsg ->
            ( model, Cmd.none )

        OnConnect _ clientId ->
            ( { model | message = clientId }, Cmd.none )

        OnDisconnect _ _ ->
            ( model, Cmd.none )


updateFromFrontend : SessionId -> ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend sessionId clientId msg model =
    case msg of
        NoOpToBackend ->
            ( model, Cmd.none )
