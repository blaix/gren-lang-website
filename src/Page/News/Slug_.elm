module Page.News.Slug_ exposing (Data, Model, Msg, page)

import Data.Article as Article exposing (Article)
import DataSource exposing (DataSource)
import Date
import Head
import Head.Seo as Seo
import Html
import Markdown.Parser
import Markdown.Renderer
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import Site
import View exposing (View)


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { slug : String }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , routes = routes
        , data = data
        }
        |> Page.buildNoState { view = view }


routes : DataSource (List RouteParams)
routes =
    Article.filePaths
        |> DataSource.map
            (List.map (\f -> RouteParams f.name))


data : RouteParams -> DataSource Data
data routeParams =
    Article.all
        |> DataSource.map
            (List.filter (\article -> article.slug == routeParams.slug))
        |> DataSource.andThen
            (\results ->
                case List.head results of
                    Just result ->
                        DataSource.succeed result

                    Nothing ->
                        DataSource.fail <|
                            "Could not find article with slug: "
                                ++ routeParams.slug
            )
        |> DataSource.map Data


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    let
        article =
            static.data.article
    in
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = Site.name
        , image = Site.defaultImage
        , description = article.description
        , locale = Nothing
        , title = Site.subTitle article.title
        }
        |> Seo.website


type alias Data =
    { article : Article }


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View msg
view _ _ static =
    let
        article =
            static.data.article
    in
    { title = Site.subTitle article.title
    , body =
        case Markdown.Parser.parse article.body of
            Ok markdown ->
                case Markdown.Renderer.render Markdown.Renderer.defaultHtmlRenderer markdown of
                    Ok html ->
                        [ Html.header []
                            [ Html.h2 [] [ Html.text article.title ]
                            , Html.small [] [ Html.text <| "Published: " ++ Date.toIsoString article.published ]
                            ]
                        , Html.p []
                            [ Html.i []
                                [ Html.text <|
                                    "Gren is a pure functional programmming language that aims to be easy to learn and "
                                        ++ "to reason about, while remaining powerful and portable enough for real-world use."
                                ]
                            ]
                        ]
                            ++ html

                    Err _ ->
                        [ Html.text "Failed to render markdown" ]

            Err _ ->
                [ Html.text "Failed to parse markdown." ]
    }
