{-# LANGUAGE DataKinds                  #-}
{-# LANGUAGE DerivingStrategies         #-}
{-# LANGUAGE DisambiguateRecordFields   #-}
{-# LANGUAGE EmptyCase                  #-}
{-# LANGUAGE FlexibleContexts           #-}
{-# LANGUAGE FlexibleInstances          #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralisedNewtypeDeriving #-}
{-# LANGUAGE LambdaCase                 #-}
{-# LANGUAGE MultiParamTypeClasses      #-}
{-# LANGUAGE NamedFieldPuns             #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# LANGUAGE QuantifiedConstraints      #-}
{-# LANGUAGE ScopedTypeVariables        #-}
{-# LANGUAGE StandaloneDeriving         #-}
{-# LANGUAGE TypeApplications           #-}
{-# LANGUAGE TypeFamilies               #-}
{-# LANGUAGE UndecidableInstances       #-}

-- | Transactions in the context of a consensus mode, and other types used in
-- the transaction submission protocol.
--
module Cardano.Api.InMode (

    -- * Transaction in a consensus mode
    TxInMode(..),
    fromConsensusGenTx,
    toConsensusGenTx,

    -- * Transaction id in a consensus mode
    TxIdInMode(..),
    toConsensusTxId,

    -- * Transaction validation errors
    TxValidationError(..),
    TxValidationErrorInMode(..),
    fromConsensusApplyTxErr,
  ) where

import           Cardano.Api.Eras
import           Cardano.Api.Modes
import           Cardano.Api.Orphans ()
import           Cardano.Api.Tx
import           Cardano.Api.TxBody
import           Data.Aeson (ToJSON(..), Value(..))
import           Data.SOP.Strict (NS (S, Z))
import           Ouroboros.Consensus.HardFork.Combinator.AcrossEras (EraMismatch)
import           Prelude

import qualified Cardano.Ledger.AuxiliaryData as Core
import qualified Cardano.Ledger.Core as Core
import qualified Cardano.Ledger.Era as Ledger
import qualified Cardano.Ledger.Shelley.Rules.Bbody as Ledger
import qualified Data.Aeson as Aeson
import qualified Ouroboros.Consensus.Byron.Ledger as Consensus
import qualified Ouroboros.Consensus.Cardano.Block as Consensus
import qualified Ouroboros.Consensus.HardFork.Combinator as Consensus
import qualified Ouroboros.Consensus.HardFork.Combinator.Degenerate as Consensus
import qualified Ouroboros.Consensus.Ledger.SupportsMempool as Consensus
import qualified Ouroboros.Consensus.Shelley.Ledger as Consensus
import qualified Ouroboros.Consensus.TypeFamilyWrappers as Consensus
import qualified Prettyprinter as PP


-- ----------------------------------------------------------------------------
-- Transactions in the context of a consensus mode
--

-- | A 'Tx' in one of the eras supported by a given protocol mode.
--
-- For multi-era modes such as the 'CardanoMode' this type is a sum of the
-- different transaction types for all the eras. It is used in the
-- LocalTxSubmission protocol.
--
data TxInMode mode where

     -- | Everything we consider a normal transaction.
     --
     TxInMode :: Tx era -> EraInMode era mode -> TxInMode mode

     -- | Byron has various things we can post to the chain which are not
     -- actually transactions. This covers: update proposals, votes and
     -- delegation certs.
     --
     TxInByronSpecial :: Consensus.GenTx Consensus.ByronBlock
                      -> EraInMode ByronEra mode -> TxInMode mode

deriving instance Show (TxInMode mode)

fromConsensusGenTx
  :: ConsensusBlockForMode mode ~ block
  => ConsensusMode mode -> Consensus.GenTx block -> TxInMode mode
fromConsensusGenTx ByronMode (Consensus.HardForkGenTx (Consensus.OneEraGenTx (Z tx'))) =
  TxInByronSpecial tx' ByronEraInByronMode

fromConsensusGenTx ShelleyMode (Consensus.HardForkGenTx (Consensus.OneEraGenTx (Z tx'))) =
  let Consensus.ShelleyTx _txid shelleyEraTx = tx'
  in TxInMode (ShelleyTx ShelleyBasedEraShelley shelleyEraTx) ShelleyEraInShelleyMode

fromConsensusGenTx CardanoMode (Consensus.HardForkGenTx (Consensus.OneEraGenTx (Z tx'))) =
  TxInByronSpecial tx' ByronEraInCardanoMode

fromConsensusGenTx CardanoMode (Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (Z tx')))) =
  let Consensus.ShelleyTx _txid shelleyEraTx = tx'
  in TxInMode (ShelleyTx ShelleyBasedEraShelley shelleyEraTx) ShelleyEraInCardanoMode

fromConsensusGenTx CardanoMode (Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (S (Z tx'))))) =
  let Consensus.ShelleyTx _txid shelleyEraTx = tx'
  in TxInMode (ShelleyTx ShelleyBasedEraAllegra shelleyEraTx) AllegraEraInCardanoMode

fromConsensusGenTx CardanoMode (Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (S (S (Z tx')))))) =
  let Consensus.ShelleyTx _txid shelleyEraTx = tx'
  in TxInMode (ShelleyTx ShelleyBasedEraMary shelleyEraTx) MaryEraInCardanoMode

fromConsensusGenTx CardanoMode (Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (S (S (S (Z tx'))))))) =
  let Consensus.ShelleyTx _txid shelleyEraTx = tx'
  in TxInMode (ShelleyTx ShelleyBasedEraAlonzo shelleyEraTx) AlonzoEraInCardanoMode

toConsensusGenTx :: ConsensusBlockForMode mode ~ block
                 => TxInMode mode
                 -> Consensus.GenTx block
toConsensusGenTx (TxInMode (ByronTx tx) ByronEraInByronMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (Z tx'))
  where
    tx' = Consensus.ByronTx (Consensus.byronIdTx tx) tx

toConsensusGenTx (TxInMode (ByronTx tx) ByronEraInCardanoMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (Z tx'))
  where
    tx' = Consensus.ByronTx (Consensus.byronIdTx tx) tx
    --TODO: add the above as mkByronTx to the consensus code,
    -- matching mkShelleyTx below

toConsensusGenTx (TxInByronSpecial gtx ByronEraInByronMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (Z gtx))

toConsensusGenTx (TxInByronSpecial gtx ByronEraInCardanoMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (Z gtx))

toConsensusGenTx (TxInMode (ShelleyTx _ tx) ShelleyEraInShelleyMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (Z tx'))
  where
    tx' = Consensus.mkShelleyTx tx

toConsensusGenTx (TxInMode (ShelleyTx _ tx) ShelleyEraInCardanoMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (Z tx')))
  where
    tx' = Consensus.mkShelleyTx tx

toConsensusGenTx (TxInMode (ShelleyTx _ tx) AllegraEraInCardanoMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (S (Z tx'))))
  where
    tx' = Consensus.mkShelleyTx tx

toConsensusGenTx (TxInMode (ShelleyTx _ tx) MaryEraInCardanoMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (S (S (Z tx')))))
  where
    tx' = Consensus.mkShelleyTx tx

toConsensusGenTx (TxInMode (ShelleyTx _ tx) AlonzoEraInCardanoMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (S (S (S (Z tx'))))))
  where
    tx' = Consensus.mkShelleyTx tx

toConsensusGenTx (TxInMode (ShelleyTx _ _tx) BabbageEraInCardanoMode) =
    Consensus.HardForkGenTx (Consensus.OneEraGenTx (S (S (S (S (Z tx'))))))
  where
    tx' = error "TODO: Babbage era - depends on consensus exposing a babbage era" -- Consensus.mkShelleyTx tx

-- ----------------------------------------------------------------------------
-- Transaction ids in the context of a consensus mode
--

-- | A 'TxId' in one of the eras supported by a given protocol mode.
--
-- For multi-era modes such as the 'CardanoMode' this type is a sum of the
-- different transaction types for all the eras. It is used in the
-- LocalTxMonitoring protocol.
--

data TxIdInMode mode where
  TxIdInMode :: TxId -> EraInMode era mode -> TxIdInMode mode

toConsensusTxId
  :: ConsensusBlockForMode mode ~ block
  => TxIdInMode mode -> Consensus.TxId  (Consensus.GenTx block)
toConsensusTxId (TxIdInMode txid ByronEraInByronMode) =
  Consensus.HardForkGenTxId . Consensus.OneEraGenTxId . Z $ Consensus.WrapGenTxId txid'
 where
  txid' :: Consensus.TxId (Consensus.GenTx Consensus.ByronBlock)
  txid' = Consensus.ByronTxId $ toByronTxId txid

toConsensusTxId (TxIdInMode t ShelleyEraInShelleyMode) =
  Consensus.HardForkGenTxId $ Consensus.OneEraGenTxId  $ Z  (Consensus.WrapGenTxId txid')
 where
  txid' :: Consensus.TxId (Consensus.GenTx (Consensus.ShelleyBlock Consensus.StandardShelley))
  txid' = Consensus.ShelleyTxId $ toShelleyTxId t

toConsensusTxId (TxIdInMode txid ByronEraInCardanoMode) =
  Consensus.HardForkGenTxId . Consensus.OneEraGenTxId . Z $ Consensus.WrapGenTxId txid'
 where
  txid' :: Consensus.TxId (Consensus.GenTx Consensus.ByronBlock)
  txid' = Consensus.ByronTxId $ toByronTxId txid

toConsensusTxId (TxIdInMode txid ShelleyEraInCardanoMode) =
  Consensus.HardForkGenTxId (Consensus.OneEraGenTxId (S (Z (Consensus.WrapGenTxId txid'))))
 where
  txid' :: Consensus.TxId (Consensus.GenTx (Consensus.ShelleyBlock Consensus.StandardShelley))
  txid' = Consensus.ShelleyTxId $ toShelleyTxId txid

toConsensusTxId (TxIdInMode txid AllegraEraInCardanoMode) =
  Consensus.HardForkGenTxId (Consensus.OneEraGenTxId (S (S (Z (Consensus.WrapGenTxId txid')))))
 where
  txid' :: Consensus.TxId (Consensus.GenTx (Consensus.ShelleyBlock Consensus.StandardAllegra))
  txid' = Consensus.ShelleyTxId $ toShelleyTxId txid

toConsensusTxId (TxIdInMode txid MaryEraInCardanoMode) =
  Consensus.HardForkGenTxId (Consensus.OneEraGenTxId (S (S (S (Z (Consensus.WrapGenTxId txid'))))))
 where
  txid' :: Consensus.TxId (Consensus.GenTx (Consensus.ShelleyBlock Consensus.StandardMary))
  txid' = Consensus.ShelleyTxId $ toShelleyTxId txid

toConsensusTxId (TxIdInMode txid AlonzoEraInCardanoMode) =
  Consensus.HardForkGenTxId (Consensus.OneEraGenTxId (S (S (S (S (Z (Consensus.WrapGenTxId txid')))))))
 where
  txid' :: Consensus.TxId (Consensus.GenTx (Consensus.ShelleyBlock Consensus.StandardAlonzo))
  txid' = Consensus.ShelleyTxId $ toShelleyTxId txid

toConsensusTxId (TxIdInMode _txid BabbageEraInCardanoMode) =
  error "TODO: Babbage era - depends on consensus exposing a babbage era"

-- ----------------------------------------------------------------------------
-- Transaction validation errors in the context of eras and consensus modes
--

-- | The transaction validations errors that can occur from trying to submit a
-- transaction to a local node. The errors are specific to an era.
--
data TxValidationError era where

     ByronTxValidationError
       :: Consensus.ApplyTxErr Consensus.ByronBlock
       -> TxValidationError ByronEra

     ShelleyTxValidationError
       :: ShelleyBasedEra era
       -> Consensus.ApplyTxErr (Consensus.ShelleyBlock (ShelleyLedgerEra era))
       -> TxValidationError era

instance ToJSON (TxValidationError era) where
  toJSON txValidationErrorInMode = case txValidationErrorInMode of
    ByronTxValidationError _applyTxError -> Aeson.Null -- TODO jky implement
    ShelleyTxValidationError ShelleyBasedEraShelley applyTxError -> applyTxErrorToJson applyTxError
    ShelleyTxValidationError ShelleyBasedEraAllegra applyTxError -> applyTxErrorToJson applyTxError
    ShelleyTxValidationError ShelleyBasedEraMary applyTxError -> applyTxErrorToJson applyTxError
    ShelleyTxValidationError ShelleyBasedEraAlonzo applyTxError -> applyTxErrorToJson applyTxError
    ShelleyTxValidationError ShelleyBasedEraBabbage _applyTxError -> Aeson.Null -- TODO implement

instance PP.Pretty (TxValidationError era) where
  pretty (ByronTxValidationError err) = mconcat
    [ "ByronTxValidationError:"
    , PP.line
    , PP.nest 2 $ PP.pretty $ show err
    ]

  pretty (ShelleyTxValidationError ShelleyBasedEraShelley err) = mconcat
    [ "ShelleyTxValidationError ShelleyBasedEraShelley:"
    , PP.line
    , PP.nest 2 $ PP.pretty $ show err
    ]

  pretty (ShelleyTxValidationError ShelleyBasedEraAllegra err) = mconcat
    [ "ShelleyTxValidationError ShelleyBasedEraAllegra:"
    , PP.line
    , PP.nest 2 $ PP.pretty $ show err
    ]

  pretty (ShelleyTxValidationError ShelleyBasedEraMary err) = mconcat
    [ "ShelleyTxValidationError ShelleyBasedEraMary:"
    , PP.line
    , PP.nest 2 $ PP.pretty $ show err
    ]

  pretty (ShelleyTxValidationError ShelleyBasedEraAlonzo err) = mconcat
    [ "ShelleyTxValidationError ShelleyBasedEraAlonzo:"
    , PP.line
    , PP.nest 2 $ PP.pretty err
    ]

  -- TODO Babbage
  pretty (ShelleyTxValidationError ShelleyBasedEraBabbage _err) = "<not available>"

-- | A 'TxValidationError' in one of the eras supported by a given protocol
-- mode.
--
-- This is used in the LocalStateQuery protocol.
--
data TxValidationErrorInMode mode where
     TxValidationErrorInMode :: TxValidationError era
                             -> EraInMode era mode
                             -> TxValidationErrorInMode mode

     TxValidationEraMismatch :: EraMismatch
                             -> TxValidationErrorInMode mode

instance PP.Pretty (TxValidationErrorInMode mode) where
  pretty (TxValidationErrorInMode e eraInMode) = mconcat
    [ "TxValidationErrorInMode"
    , PP.line
    , PP.nest 2 $ mconcat
      [ "era in mode:" <> PP.pretty (show eraInMode)
      , PP.line
      , "error:"
      , PP.line
      , PP.nest 2 $ PP.pretty e
      ]
    ]

  pretty (TxValidationEraMismatch e) = mconcat
    [ "TxValidationErrorInMode"
    , PP.line
    , PP.nest 2 $ mconcat
      [ "error:"
      , PP.line
      , PP.nest 2 $ PP.pretty (show e)
      ]
    ]

fromConsensusApplyTxErr :: ConsensusBlockForMode mode ~ block
                        => ConsensusMode mode
                        -> Consensus.ApplyTxErr block
                        -> TxValidationErrorInMode mode
fromConsensusApplyTxErr ByronMode (Consensus.DegenApplyTxErr err) =
    TxValidationErrorInMode
      (ByronTxValidationError err)
      ByronEraInByronMode

fromConsensusApplyTxErr ShelleyMode (Consensus.DegenApplyTxErr err) =
    TxValidationErrorInMode
      (ShelleyTxValidationError ShelleyBasedEraShelley err)
      ShelleyEraInShelleyMode

fromConsensusApplyTxErr CardanoMode (Consensus.ApplyTxErrByron err) =
    TxValidationErrorInMode
      (ByronTxValidationError err)
      ByronEraInCardanoMode

fromConsensusApplyTxErr CardanoMode (Consensus.ApplyTxErrShelley err) =
    TxValidationErrorInMode
      (ShelleyTxValidationError ShelleyBasedEraShelley err)
      ShelleyEraInCardanoMode

fromConsensusApplyTxErr CardanoMode (Consensus.ApplyTxErrAllegra err) =
    TxValidationErrorInMode
      (ShelleyTxValidationError ShelleyBasedEraAllegra err)
      AllegraEraInCardanoMode

fromConsensusApplyTxErr CardanoMode (Consensus.ApplyTxErrMary err) =
    TxValidationErrorInMode
      (ShelleyTxValidationError ShelleyBasedEraMary err)
      MaryEraInCardanoMode

fromConsensusApplyTxErr CardanoMode (Consensus.ApplyTxErrAlonzo err) =
    TxValidationErrorInMode
      (ShelleyTxValidationError ShelleyBasedEraAlonzo err)
      AlonzoEraInCardanoMode

fromConsensusApplyTxErr CardanoMode (Consensus.ApplyTxErrWrongEra err) =
    TxValidationEraMismatch err

applyTxErrorToJson ::
  ( Consensus.ShelleyBasedEra era
  , ToJSON (Core.AuxiliaryDataHash (Ledger.Crypto era))
  , ToJSON (Core.TxOut era)
  , ToJSON (Core.Value era)
  , ToJSON (Ledger.PredicateFailure (Core.EraRule "DELEGS" era))
  , ToJSON (Ledger.PredicateFailure (Core.EraRule "PPUP" era))
  , ToJSON (Ledger.PredicateFailure (Core.EraRule "UTXO" era))
  , ToJSON (Ledger.PredicateFailure (Core.EraRule "UTXOW" era))
  ) => Consensus.ApplyTxErr (Consensus.ShelleyBlock era) -> Value
applyTxErrorToJson (Consensus.ApplyTxError predicateFailures) = toJSON (fmap toJSON predicateFailures)