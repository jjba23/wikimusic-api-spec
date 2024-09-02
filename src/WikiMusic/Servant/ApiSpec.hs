{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE NoFieldSelectors #-}

module WikiMusic.Servant.ApiSpec
  ( PrivateAPI,
    PublicAPI,
    WikiMusicAPIServer,
    APIDocsServer,
    ArtistsAPI,
    SongsAPI,
    AuthAPI,
    GenresAPI,
    WithBaseEntityRoutes,
    WithComments,
    WithOpinions,
    WithArtworks,
    WithArtworkOrders,
    LoginRespondWithAuth,
    WithSearch,
    WithIdentifier,
  )
where

import Data.OpenApi qualified
import Data.UUID hiding (fromString)
import Relude
import Servant as S
import WikiMusic.Interaction.Model.Artist
import WikiMusic.Interaction.Model.Auth
import WikiMusic.Interaction.Model.Genre
import WikiMusic.Interaction.Model.Song
import WikiMusic.Interaction.Model.User
import WikiMusic.Model.Auth
import WikiMusic.Model.Other

type WikiMusicAPIServer =
  PrivateAPI
    :<|> SwaggerAPI
    :<|> PublicAPI

type APIDocsServer = PublicAPI :<|> PrivateAPI

type SwaggerAPI = "swagger.json" :> Get '[JSON] Data.OpenApi.OpenApi

type WithAuth = Header "x-wikimusic-auth" Text

type PrivateAPI =
  ArtistsAPI
    :<|> GenresAPI
    :<|> SongsAPI
    :<|> AuthAPI

type PublicAPI =
  "login"
    :> ReqBody '[JSON] LoginRequest
    :> LoginRespondWithAuth
    :<|> "reset-password"
      :> ( "email"
             :> Capture "email" Text
             :> Post '[JSON] MakeResetPasswordLinkResponse
             :<|> "do"
               :> ReqBody '[JSON] DoPasswordResetRequest
               :> Verb 'POST 204 '[JSON] ()
         )
    :<|> "system-information"
      :> Get '[JSON] SystemInformationResponse

type ArtistsAPI =
  "artists"
    :> ( WithBaseEntityRoutes
           :<|> PageGet GetArtistsQueryResponse
           :<|> SearchGet GetArtistsQueryResponse
           :<|> WithDetailsFromIdentifier GetArtistsQueryResponse
           :<|> WithAuth :> ReqBody '[JSON] InsertArtistsRequest :> Post '[JSON] InsertArtistsCommandResponse
           :<|> WithComments InsertArtistCommentsRequest InsertArtistCommentsCommandResponse
           :<|> WithOpinions UpsertArtistOpinionsRequest UpsertArtistOpinionsCommandResponse
           :<|> WithArtworks InsertArtistArtworksRequest InsertArtistArtworksCommandResponse
           :<|> WithArtworkOrders ArtistArtworkOrderUpdateRequest
           :<|> "edit" :> WithAuth :> ReqBody '[JSON] ArtistDeltaRequest :> Patch '[JSON] ()
       )

type SongsAPI =
  "songs"
    :> ( WithBaseEntityRoutes
           :<|> PageGet GetSongsQueryResponse
           :<|> SearchGet GetSongsQueryResponse
           :<|> WithDetailsFromIdentifier GetSongsQueryResponse
           :<|> WithAuth :> ReqBody '[JSON] InsertSongsRequest :> Post '[JSON] InsertSongsCommandResponse
           :<|> WithComments InsertSongCommentsRequest InsertSongCommentsCommandResponse
           :<|> WithOpinions UpsertSongOpinionsRequest UpsertSongOpinionsCommandResponse
           :<|> WithArtworks InsertSongArtworksRequest InsertSongArtworksCommandResponse
           :<|> "artists" :> WithAuth :> ReqBody '[JSON] InsertArtistsOfSongsRequest :> Post '[JSON] InsertArtistsOfSongCommandResponse
           :<|> "artists" :> WithAuth :> ReqBody '[JSON] InsertArtistsOfSongsRequest :> Delete '[JSON] ()
           :<|> WithArtworkOrders SongArtworkOrderUpdateRequest
           :<|> "edit" :> WithAuth :> ReqBody '[JSON] SongDeltaRequest :> Patch '[JSON] ()
           :<|> "contents" :> WithAuth :> ReqBody '[JSON] InsertSongContentsRequest :> Post '[JSON] InsertSongContentsCommandResponse
           :<|> "contents" :> WithAuth :> WithIdentifier :> Delete '[JSON] ()
           :<|> "contents" :> WithAuth :> ReqBody '[JSON] SongContentDeltaRequest :> Patch '[JSON] ()
       )

type GenresAPI =
  "genres"
    :> ( WithBaseEntityRoutes
           :<|> PageGet GetGenresQueryResponse
           :<|> SearchGet GetGenresQueryResponse
           :<|> WithDetailsFromIdentifier GetGenresQueryResponse
           :<|> WithAuth :> ReqBody '[JSON] InsertGenresRequest :> Post '[JSON] InsertGenresCommandResponse
           :<|> WithComments InsertGenreCommentsRequest InsertGenreCommentsCommandResponse
           :<|> WithOpinions UpsertGenreOpinionsRequest UpsertGenreOpinionsCommandResponse
           :<|> WithArtworks InsertGenreArtworksRequest InsertGenreArtworksCommandResponse
           :<|> WithArtworkOrders GenreArtworkOrderUpdateRequest
           :<|> "edit" :> WithAuth :> ReqBody '[JSON] GenreDeltaRequest :> Patch '[JSON] ()
       )

type AuthAPI =
  "me" :> WithAuth :> Get '[JSON] GetMeQueryResponse
    :<|> "users"
      :> ( "invite" :> WithAuth :> ReqBody '[JSON] InviteUsersRequest :> Post '[JSON] MakeResetPasswordLinkResponse
             :<|> "delete" :> WithAuth :> ReqBody '[JSON] DeleteUsersRequest :> Post '[JSON] ()
         )

type LoginRespondWithAuth =
  Verb
    'POST
    204
    '[JSON]
    ( Headers
        '[WithAuth]
        NoContent
    )

type WithIdentifier = Capture "identifier" UUID

type WithSearch = Capture "searchInput" Text

type WithBaseEntityRoutes =
  WithAuth :> WithIdentifier :> Delete '[JSON] ()
    :<|> "comments" :> WithAuth :> WithIdentifier :> Delete '[JSON] ()
    :<|> "opinions" :> WithAuth :> WithIdentifier :> Delete '[JSON] ()
    :<|> "artworks" :> WithAuth :> WithIdentifier :> Delete '[JSON] ()

type WithComments a b = "comments" :> WithAuth :> ReqBody '[JSON] a :> Post '[JSON] b

type WithOpinions a b = "opinions" :> WithAuth :> ReqBody '[JSON] a :> Post '[JSON] b

type WithArtworks a b = "artworks" :> WithAuth :> ReqBody '[JSON] a :> Post '[JSON] b

type WithArtworkOrders a = "artworks" :> "order" :> WithAuth :> ReqBody '[JSON] a :> Patch '[JSON] ()

type WithDetailsFromIdentifier a = "identifier" :> WithAuth :> WithIdentifier :> Get '[JSON] a

type PageGet a =
  WithAuth
    :> QueryParam "limit" Int
    :> QueryParam "offset" Int
    :> QueryParam "sort-order" Text
    :> QueryParam "include" Text
    :> Get '[JSON] a

type SearchGet a =
  "search"
    :> WithAuth
    :> WithSearch
    :> QueryParam "limit" Int
    :> QueryParam "offset" Int
    :> QueryParam "sort-order" Text
    :> QueryParam "include" Text
    :> Get '[JSON] a
