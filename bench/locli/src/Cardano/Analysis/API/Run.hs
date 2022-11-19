{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE StrictData #-}
{-# OPTIONS_GHC -Wno-incomplete-patterns -Wno-name-shadowing -Wno-orphans #-}
module Cardano.Analysis.API.Run (module Cardano.Analysis.API.Run) where

import Cardano.Prelude

import Control.Monad (fail)
import Data.Aeson qualified as Aeson
import Data.Aeson (FromJSON(..), Object, ToJSON(..), withObject, (.:), (.:?))
import Data.Text qualified as T
import Data.Time.Clock hiding (secondsToNominalDiffTime)
import Data.Time.Clock.POSIX

import Cardano.Util
import Cardano.Analysis.API.ChainFilter
import Cardano.Analysis.API.Context
import Cardano.Analysis.API.Ground
import Cardano.Analysis.API.LocliVersion

-- | Explain the poor human a little bit of what was going on:
data Anchor
  = Anchor
  { aRuns    :: [Text]
  , aFilters :: ([FilterName], [ChainFilter])
  , aSlots   :: Maybe (DataDomain SlotNo)
  , aBlocks  :: Maybe (DataDomain BlockNo)
  , aVersion :: Cardano.Analysis.API.LocliVersion.LocliVersion
  , aWhen    :: UTCTime
  }

runAnchor :: Run -> UTCTime -> ([FilterName], [ChainFilter]) -> Maybe (DataDomain SlotNo) -> Maybe (DataDomain BlockNo) -> Anchor
runAnchor Run{..} = tagsAnchor [tag metadata]

tagsAnchor :: [Text] -> UTCTime -> ([FilterName], [ChainFilter]) -> Maybe (DataDomain SlotNo) -> Maybe (DataDomain BlockNo) -> Anchor
tagsAnchor aRuns aWhen aFilters aSlots aBlocks =
  Anchor { aVersion = getLocliVersion, .. }

renderAnchor :: Anchor -> Text
renderAnchor a = mconcat
  [ "runs: ", renderAnchorRuns a, ", "
  , renderAnchorNoRuns a
  ]

renderAnchorRuns :: Anchor -> Text
renderAnchorRuns Anchor{..} = mconcat
  [ T.intercalate ", " aRuns ]

renderAnchorFiltersAndDomains :: Anchor -> Text
renderAnchorFiltersAndDomains a@Anchor{..} = mconcat
  [ "filters: ", case fst aFilters of
                   [] -> "unfiltered"
                   xs -> T.intercalate ", " (unFilterName <$> xs)
  , renderAnchorDomains a]

renderAnchorDomains :: Anchor -> Text
renderAnchorDomains Anchor{..} = mconcat $
  maybe [] ((:[]) . renderDomain "slot"  (show . unSlotNo)) aSlots
  <>
  maybe [] ((:[]) . renderDomain "block" (show . unBlockNo)) aBlocks
 where renderDomain :: Text -> (a -> Text) -> DataDomain a -> Text
       renderDomain ty r DataDomain{..} = mconcat
         [ ", ", ty
         , " range: raw(", r ddRawFirst,      "-", r ddRawLast, ", ", show ddRawCount, " total)"
         ,   " filtered("
         , maybe "none" r ddFilteredFirst, "-"
         , maybe "none" r ddFilteredLast,  ", ", show ddFilteredCount, " total)"
         ]

renderAnchorNoRuns :: Anchor -> Text
renderAnchorNoRuns a@Anchor{..} = mconcat
  [ renderAnchorFiltersAndDomains a
  , ", ", renderProgramAndVersion aVersion
  , ", analysed at ", renderAnchorDate a
  ]

-- Rounds time to seconds.
renderAnchorDate :: Anchor -> Text
renderAnchorDate = show . posixSecondsToUTCTime . secondsToNominalDiffTime . fromIntegral @Int . round . utcTimeToPOSIXSeconds . aWhen

data AnalysisCmdError
  = AnalysisCmdError                                   !Text
  | MissingRunContext
  | MissingLogfiles
  | RunMetaParseError      !(JsonInputFile RunPartial) !Text
  | GenesisParseError      !(JsonInputFile Genesis)    !Text
  | ChainFiltersParseError !JsonFilterFile             !Text
  deriving Show

data ARunWith a
  = Run
  { genesisSpec      :: GenesisSpec
  , generatorProfile :: GeneratorProfile
  , metadata         :: Metadata
  , genesis          :: a
  }
  deriving (Generic, Show, ToJSON)

type RunPartial = ARunWith ()
type Run        = ARunWith Genesis

instance FromJSON RunPartial where
  parseJSON = withObject "Run" $ \v -> do
    meta :: Object <- v .: "meta"
    profile_content <- meta .: "profile_content"
    generator <- profile_content .: "generator"
    --
    genesisSpec      <- profile_content .: "genesis"
    generatorProfile <- parseJSON $ Aeson.Object generator
    --
    tag       <- meta .: "tag"
    profile   <- meta .: "profile"
    batch     <- meta .: "batch"
    manifest  <- meta .: "manifest"

    eraGtor   <- generator       .:? "era"
    eraTop    <- profile_content .:? "era"
    era <- case eraGtor <|> eraTop of
      Just x -> pure x
      Nothing -> fail "While parsing run metafile:  missing era specification"
    --
    let metadata = Metadata{..}
        genesis  = ()
    pure Run{..}

readRun :: JsonInputFile Genesis -> JsonInputFile RunPartial -> ExceptT AnalysisCmdError IO Run
readRun shelleyGenesis runmeta = do
  runPartial <- readJsonData runmeta        (RunMetaParseError runmeta)
  progress "meta"    (Q $ unJsonInputFile runmeta)
  run        <- readJsonData shelleyGenesis (GenesisParseError shelleyGenesis)
                <&> completeRun runPartial
  progress "genesis" (Q $ unJsonInputFile shelleyGenesis)
  progress "run"     (J run)
  pure run

 where
   completeRun :: RunPartial -> Genesis -> Run
   completeRun Run{..} g = Run { genesis = g, .. }
