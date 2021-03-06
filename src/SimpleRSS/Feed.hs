{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}

module SimpleRSS.Feed
    ( getChannels
    , ChannelMap
    , Channel
    ) where

import Control.Applicative
import Data.Aeson hiding (json)
import Data.Maybe
import Data.Swagger
import Data.Text (Text, pack)
import Data.UUID
import Data.UUID.V4
import GHC.Generics
import System.Directory
import System.FilePath
import Text.Feed.Import
import Text.Feed.Types hiding (RSSItem, Item)
import Text.RSS.Syntax
import qualified Data.Map.Strict as Map

data Channel = Channel
    { name :: Text
    , items :: [Item]
    } deriving (Generic, Show)

data Item = Item
    { title :: Text
    , content :: Text
    } deriving (Generic, Show)

instance ToJSON Channel
instance ToJSON Item

instance ToSchema Channel
instance ToSchema Item

type ChannelMap = Map.Map UUID Channel

getChannels :: FilePath -> IO ChannelMap
getChannels path = do
    feedFiles <- do
        filesWithoutPath <- filter (\file -> takeExtension file == ".xml") <$> listDirectory path
        return $ map (path </>) filesWithoutPath

    channels <- do
        feeds <- mapM parseFeedFromFile feedFiles
        return $ map feedToChannel feeds

    uuidFeedPairs <- mapM (\c -> do
            uuid <- nextRandom
            return (uuid, c)
        ) channels

    return $ Map.fromList uuidFeedPairs

feedToChannel :: Feed -> Channel
feedToChannel (RSSFeed (RSS _ _ RSSChannel{..} _)) = Channel rssTitle (map itemToItem rssItems)
feedToChannel _ = error "Only RSSFeed supported"

itemToItem :: RSSItem -> Item
itemToItem RSSItem{..} =
    let title   = fromJust $ rssItemTitle <|> Just ""
        content = fromJust $ rssItemDescription <|> Just ""
    in Item { title = title, content = content}
