{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE EmptyCase #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE GADTs #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE InstanceSigs #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ViewPatterns #-}

-- The Shelley ledger uses promoted data kinds which we have to use, but we do
-- not export any from this API. We also use them unticked as nature intended.
{-# LANGUAGE DataKinds #-}
{-# OPTIONS_GHC -Wno-unticked-promoted-constructors #-}

-- | This module provides a library interface for interacting with Cardano as
-- a user of the system.
--
-- It is intended to be used to write tools and
--
-- In the interest of simplicity it glosses over some details of the system.
-- Most simple tools should be able to work just using this interface,
-- however you can go deeper and expose the types from the underlying libraries
-- using "Cardano.Api.Byron" or "Cardano.Api.Shelley".
--
module Cardano.Api.Typed (
    -- * Eras
    Byron,
    Shelley,
    Allegra,
    Mary,
    HasTypeProxy(..),
    AsType(..),
    -- * Cryptographic key interface
    -- $keys
    Key,
    VerificationKey(..),
    SigningKey(..),
    getVerificationKey,
    verificationKeyHash,
    castVerificationKey,
    castSigningKey,

    -- ** Generating keys
    generateSigningKey,
    deterministicSigningKey,
    deterministicSigningKeySeedSize,
    Crypto.Seed,
    Crypto.mkSeedFromBytes,
    Crypto.readSeedFromSystemEntropy,

    -- ** Hashes
    -- | In Cardano most keys are identified by their hash, and hashes are
    -- used in many other places.
    Hash(..),
    castHash,

    -- * Payment addresses
    -- | Constructing and inspecting normal payment addresses
    Address(..),
    NetworkId(..),
    -- * Byron addresses
    makeByronAddress,
    ByronKey,
    -- * Shelley addresses
    makeShelleyAddress,
    PaymentCredential(..),
    StakeAddressReference(..),
    PaymentKey,
    PaymentExtendedKey,

    -- * Stake addresses
    -- | Constructing and inspecting stake addresses
    StakeAddress(..),
    StakeCredential(..),
    makeStakeAddress,
    StakeKey,
    StakeExtendedKey,

    -- * Currency values
    -- ** Ada \/ Lovelace
    Lovelace(..),

    -- ** Multi-asset values
    Quantity(..),
    PolicyId(..),
    AssetName(..),
    AssetId(..),
    Value,
    selectAsset,
    valueFromList,
    valueToList,
    filterValue,
    negateValue,

    -- ** Ada \/ Lovelace within multi-asset values
    quantityToLovelace,
    lovelaceToQuantity,
    selectLovelace,
    lovelaceToValue,

    -- * Building transactions
    -- | Constructing and inspecting transactions
    TxBody(..),
    TxId(..),
    getTxId,
    TxIn(..),
    TxIx(..),
    TxOut(..),
    TxOutValue(..),
    AdaOnlyInEra(..),
    MultiAssetInEra(..),
    TTL,
    TxFee,
    MintValue(..),
    makeByronTransaction,
    makeShelleyTransaction,
    SlotNo(..),
    TxExtraContent(..),
    txExtraContentEmpty,
    Certificate(..),

    -- * Signing transactions
    -- | Creating transaction witnesses one by one, or all in one go.
    Tx(..),
    getTxBody,
    getTxWitnesses,

    -- ** Signing in one go
    ShelleySigningKey,
    toShelleySigningKey,
    signByronTransaction,
    signShelleyTransaction,
    -- ** Incremental signing and separate witnesses
    makeSignedTransaction,
    Witness(..),
    makeByronKeyWitness,
    ShelleyWitnessSigningKey(..),
    makeShelleyKeyWitness,
    WitnessNetworkIdOrByronAddress (..),
    makeShelleyBootstrapWitness,
    makeScriptWitness,
    makeShelleySignature,
    getShelleyKeyWitnessVerificationKey,

    -- * Fee calculation
    transactionFee,
    estimateTransactionFee,

    -- * Transaction metadata
    -- | Embedding additional structured data within transactions.
    TxMetadata (TxMetadata, TxMetadataShelley),

    -- ** Constructing metadata
    TxMetadataValue(..),
    makeTransactionMetadata,

    -- ** Validating metadata
    validateTxMetadata,
    TxMetadataRangeError (..),

    -- ** Converstion to\/from JSON
    TxMetadataJsonSchema (..),
    metadataFromJson,
    metadataToJson,
    metadataValueToJsonNoSchema,
    TxMetadataJsonError (..),
    TxMetadataJsonSchemaError (..),

    -- * Registering stake address and delegating
    -- | Certificates that are embedded in transactions for registering and
    -- unregistering stake address, and for setting the stake pool delegation
    -- choice for a stake address.
    makeStakeAddressRegistrationCertificate,
    makeStakeAddressDeregistrationCertificate,
    makeStakeAddressDelegationCertificate,

    -- * Registering stake pools
    -- | Certificates that are embedded in transactions for registering and
    -- retiring stake pools. This includes updating the stake pool parameters.
    makeStakePoolRegistrationCertificate,
    makeStakePoolRetirementCertificate,
    StakePoolParameters(..),
    StakePoolRelay(..),
    StakePoolMetadataReference(..),

    -- ** Stake pool off-chain metadata
    StakePoolMetadata(..),
    validateAndHashStakePoolMetadata,
    StakePoolMetadataValidationError(..),

    -- * Scripts
    -- | Both 'PaymentCredential's and 'StakeCredential's can use scripts.
    -- Shelley supports multi-signatures via scripts.
    Script(..),
    parseScript,
    parseScriptAny,
    parseScriptAll,
    parseScriptAtLeast,
    parseScriptSig,

    -- ** Script addresses
    -- | Making addresses from scripts.
    ScriptHash,
    scriptHash,

    -- ** Multi-signature scripts
    -- | Making multi-signature scripts.
    SimpleScript(..),
    ScriptFeatureInEra(..),
    SignatureFeature,
    TimeLocksFeature,
    -- *** Deprecated aliases
    MultiSigScript,
    makeMultiSigScript,

    -- * Serialisation
    -- | Support for serialising data in JSON, CBOR and text files.

    -- ** CBOR
    SerialiseAsCBOR,
    ToCBOR,
    FromCBOR,
    serialiseToCBOR,
    deserialiseFromCBOR,

    -- ** JSON
    ToJSON,
    FromJSON,
    serialiseToJSON,
    deserialiseFromJSON,

    -- ** Bech32
    SerialiseAsBech32,
    serialiseToBech32,
    deserialiseFromBech32,
    deserialiseAnyOfFromBech32,
    Bech32DecodeError(..),

    -- ** Addresses
    -- | Address serialisation is (sadly) special
    SerialiseAddress,
    serialiseAddress,
    deserialiseAddress,

    -- ** Raw binary
    -- | Some types have a natural raw binary format.
    SerialiseAsRawBytes,
    serialiseToRawBytes,
    deserialiseFromRawBytes,
    serialiseToRawBytesHex,
    deserialiseFromRawBytesHex,

    -- ** Text envelope
    -- | Support for a envelope file format with text headers and a hex-encoded
    -- binary payload.
    HasTextEnvelope(..),
    TextEnvelope(..),
    TextEnvelopeType,
    TextEnvelopeDescr,
    textEnvelopeRawCBOR,
    serialiseToTextEnvelope,
    deserialiseFromTextEnvelope,
    TextEnvelopeError(..),
    readFileTextEnvelope,
    writeFileTextEnvelope,
    writeFileTextEnvelopeWithOwnerPermissions,
    readTextEnvelopeFromFile,
    readTextEnvelopeOfTypeFromFile,

    -- *** Reading one of several key types
    FromSomeType(..),
    deserialiseFromTextEnvelopeAnyOf,
    readFileTextEnvelopeAnyOf,

    -- * Errors
    Error(..),
    throwErrorAsException,
    FileError(..),

    -- * Node interaction
    -- | Operations that involve talking to a local Cardano node.

    -- ** Queries
    -- ** Submitting transactions

    -- ** Low level protocol interaction with a Cardano node
    connectToLocalNode,
    LocalNodeConnectInfo(..),
    ByronMode,
    ShelleyMode,
    CardanoMode,
    NodeConsensusMode(..),
    LocalNodeClientProtocols(..),
    nullLocalNodeClientProtocols,
    withNodeProtocolClient,
--  connectToRemoteNode,

    -- *** Chain sync protocol
    ChainSyncClient(..),

    -- *** Local tx submission
    LocalTxSubmissionClient(..),
    submitTxToNodeLocal,

    -- *** Local state query
    LocalStateQueryClient(..),
    queryNodeLocalState,

    -- * Node operation
    -- | Support for the steps needed to operate a node, including the
    -- operator's offline keys, operational KES and VRF keys, and operational
    -- certificates.

    -- ** Stake pool operator's keys
    StakePoolKey,
    PoolId,

    -- ** KES keys
    KesKey,

    -- ** VRF keys
    VrfKey,

    -- ** Operational certificates
    OperationalCertificate(..),
    OperationalCertificateIssueCounter(..),
    Shelley.KESPeriod(..),
    OperationalCertIssueError(..),
    issueOperationalCertificate,

    -- * Genesis file
    -- | Types and functions needed to inspect or create a genesis file.
    GenesisKey,
    GenesisExtendedKey,
    GenesisDelegateKey,
    GenesisDelegateExtendedKey,
    GenesisUTxOKey,
    genesisUTxOPseudoTxIn,

    -- * Special transactions
    -- | There are various additional things that can be embedded in a
    -- transaction for special operations.
    makeMIRCertificate,
    makeGenesisKeyDelegationCertificate,

    -- ** Protocol parameter updates
    UpdateProposal(..),
    ProtocolParametersUpdate(..),
    EpochNo(..),
    NetworkMagic(..),
    makeShelleyUpdateProposal,

    -- ** Conversions
    --TODO: arrange not to export these
    toByronNetworkMagic,
    toByronProtocolMagicId,
    toByronRequiresNetworkMagic,
    toByronLovelace,
    toByronTxIn,
    toByronTxId,
    toByronTxOut,
    toShelleyNetwork,
    toNetworkMagic,

    Shelley.Addr(..),
    Shelley.Coin(..),
    EpochSize(..),
    Shelley.GenDelegPair(..),
    Shelley.KeyRole (..),
    Shelley.KeyHash(..),
    Shelley.PParams'(..),
    Shelley.PParamsUpdate,
    Shelley.VerKeyVRF,
    StandardShelley,
    StandardAllegra,
    StandardMary,
    Shelley.emptyPParams,
    Shelley.truncateUnitInterval,
    emptyGenesisStaking,
    secondsToNominalDiffTime
  ) where

import           Prelude

import qualified Data.List.NonEmpty as NonEmpty
import           Data.Maybe
import           Data.String (IsString)
import           Data.Void (Void)
import           Data.Word
import           Numeric.Natural

import           Data.ByteString (ByteString)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as LBS
import qualified Data.ByteString.Short as SBS

import qualified Data.Map.Strict as Map
import qualified Data.Sequence.Strict as Seq
import qualified Data.Set as Set
import qualified Data.Vector as Vector

import           Control.Concurrent.STM
import           Control.Tracer (nullTracer)

--
-- Common types, consensus, network
--
import           Cardano.Binary (Annotated (..), reAnnotate, recoverBytes)
import qualified Cardano.Binary as CBOR
import qualified Cardano.Prelude as CBOR (cborError)
import qualified Shelley.Spec.Ledger.Serialization as CBOR (CBORGroup (..), decodeNullMaybe,
                     encodeNullMaybe)

import           Cardano.Slotting.Slot (EpochNo (..), EpochSize (..), SlotNo (..))

-- TODO: it'd be nice if the network imports needed were a bit more coherent
import           Ouroboros.Network.Block (Point, Tip)
import           Ouroboros.Network.Mux (MuxMode (InitiatorMode), MuxPeer (..),
                     RunMiniProtocol (InitiatorProtocolOnly))
import           Ouroboros.Network.NodeToClient (NetworkConnectTracers (..),
                     NodeToClientProtocols (..), NodeToClientVersionData (..), chainSyncPeerNull,
                     connectTo, foldMapVersions, localSnocket, localStateQueryPeerNull,
                     localTxSubmissionPeerNull, versionedNodeToClientProtocols, withIOManager)
import           Ouroboros.Network.Util.ShowProxy (ShowProxy)

-- TODO: it'd be nice if the consensus imports needed were a bit more coherent
import           Ouroboros.Consensus.Block (BlockProtocol)
import           Ouroboros.Consensus.Cardano (ProtocolClient, protocolClientInfo)
import           Ouroboros.Consensus.Ledger.Query (Query, ShowQuery)
import           Ouroboros.Consensus.Ledger.SupportsMempool (ApplyTxErr, GenTx)
import           Ouroboros.Consensus.Network.NodeToClient (Codecs' (..), clientCodecs)
import           Ouroboros.Consensus.Node.NetworkProtocolVersion (BlockNodeToClientVersion,
                     SupportedNetworkProtocolVersion, supportedNodeToClientVersions)
import           Ouroboros.Consensus.Node.ProtocolInfo (ProtocolClientInfo (..))
import           Ouroboros.Consensus.Node.Run (SerialiseNodeToClientConstraints)
import           Ouroboros.Consensus.Shelley.Node (emptyGenesisStaking)
import           Ouroboros.Consensus.Util.Time (secondsToNominalDiffTime)

import           Ouroboros.Consensus.Cardano.Block (CardanoBlock)
import           Ouroboros.Consensus.Cardano.ByronHFC (ByronBlockHFC)
import           Ouroboros.Consensus.Cardano.ShelleyHFC (ShelleyBlockHFC)

--
-- Crypto API used by consensus and Shelley (and should be used by Byron)
--
import qualified Cardano.Crypto.DSIGN.Class as Crypto
import qualified Cardano.Crypto.Hash.Class as Crypto
import qualified Cardano.Crypto.Seed as Crypto
import qualified Cardano.Crypto.Util as Crypto
import qualified Cardano.Crypto.Wallet as Crypto.HD

--
-- Byron imports
--
import qualified Cardano.Crypto.Hashing as Byron
import qualified Cardano.Crypto.ProtocolMagic as Byron
import qualified Cardano.Crypto.Signing as Byron

import qualified Cardano.Chain.Common as Byron
import qualified Cardano.Chain.Slotting as Byron
import qualified Cardano.Chain.UTxO as Byron


--
-- Shelley imports
--
import           Ouroboros.Consensus.Shelley.Eras (StandardAllegra, StandardShelley, StandardMary)
import           Ouroboros.Consensus.Shelley.Protocol.Crypto (StandardCrypto)

import qualified Cardano.Ledger.Core as Shelley (Script)

import qualified Shelley.Spec.Ledger.Address as Shelley
import qualified Shelley.Spec.Ledger.Address.Bootstrap as Shelley
import           Shelley.Spec.Ledger.BaseTypes (maybeToStrictMaybe, strictMaybeToMaybe)
import qualified Shelley.Spec.Ledger.BaseTypes as Shelley
import qualified Shelley.Spec.Ledger.Coin as Shelley
import qualified Shelley.Spec.Ledger.Credential as Shelley
import qualified Shelley.Spec.Ledger.Genesis as Shelley
import qualified Shelley.Spec.Ledger.Hashing as Shelley
import qualified Shelley.Spec.Ledger.Keys as Shelley
import qualified Shelley.Spec.Ledger.LedgerState as Shelley
import qualified Shelley.Spec.Ledger.MetaData as Shelley
import qualified Shelley.Spec.Ledger.OCert as Shelley
import qualified Shelley.Spec.Ledger.PParams as Shelley
import qualified Shelley.Spec.Ledger.Scripts as Shelley
import qualified Shelley.Spec.Ledger.Tx as Shelley
import qualified Shelley.Spec.Ledger.TxBody as Shelley
import qualified Shelley.Spec.Ledger.UTxO as Shelley

import qualified Cardano.Ledger.ShelleyMA.Scripts as Allegra


-- TODO: replace the above with
--import qualified Cardano.Api.Byron   as Byron
--import qualified Cardano.Api.Shelley as Shelley

--
-- Other config and common types
--
import           Cardano.Api.Protocol.Byron (mkNodeClientProtocolByron)
import           Cardano.Api.Protocol.Cardano (mkNodeClientProtocolCardano)
import           Cardano.Api.Protocol.Shelley (mkNodeClientProtocolShelley)
import qualified Cardano.Api.Shelley.Serialisation.Legacy as Legacy

import           Ouroboros.Network.Protocol.ChainSync.Client as ChainSync
import           Ouroboros.Network.Protocol.LocalStateQuery.Client as StateQuery
import           Ouroboros.Network.Protocol.LocalStateQuery.Type (AcquireFailure)
import           Ouroboros.Network.Protocol.LocalTxSubmission.Client as TxSubmission

import           Cardano.Api.Address
import           Cardano.Api.Certificate
import           Cardano.Api.Eras
import           Cardano.Api.Error
import           Cardano.Api.Hash
import           Cardano.Api.HasTypeProxy
import           Cardano.Api.Key
import           Cardano.Api.KeysByron
import           Cardano.Api.KeysPraos
import           Cardano.Api.KeysShelley
import           Cardano.Api.NetworkId
import           Cardano.Api.ProtocolParameters
import           Cardano.Api.Script
import           Cardano.Api.SerialiseBech32
import           Cardano.Api.SerialiseCBOR
import           Cardano.Api.SerialiseJSON
import           Cardano.Api.SerialiseRaw
import           Cardano.Api.SerialiseTextEnvelope
import           Cardano.Api.StakePoolMetadata
import           Cardano.Api.TxMetadata
import           Cardano.Api.Utils
import           Cardano.Api.Value


{- HLINT ignore "Redundant flip" -}

-- ----------------------------------------------------------------------------
-- Keys key keys!
--



-- $keys
-- Cardano has lots of cryptographic keys used for lots of different purposes.
-- Some keys have different representations, but most are just using keys in
-- different roles.
--
-- To allow for the different representations and to avoid mistakes we
-- distinguish the key /role/. These are type level distinctions, so each of
-- these roles is a type level tag.
--


-- ----------------------------------------------------------------------------
-- Transaction Ids
--

newtype TxId = TxId (Shelley.Hash StandardCrypto ())
  deriving stock (Eq, Ord, Show)
  deriving newtype (IsString)
               -- We use the Shelley representation and convert the Byron one

instance HasTypeProxy TxId where
    data AsType TxId = AsTxId
    proxyToAsType _ = AsTxId

instance SerialiseAsRawBytes TxId where
    serialiseToRawBytes (TxId h) = Crypto.hashToBytes h
    deserialiseFromRawBytes AsTxId bs = TxId <$> Crypto.hashFromBytes bs

toByronTxId :: TxId -> Byron.TxId
toByronTxId (TxId h) =
    Byron.unsafeHashFromBytes (Crypto.hashToBytes h)

toShelleyTxId :: TxId -> Shelley.TxId StandardShelley
toShelleyTxId (TxId h) =
    Shelley.TxId (Crypto.castHash h)

-- | Calculate the transaction identifier for a 'TxBody'.
--
getTxId :: TxBody era -> TxId
getTxId (ByronTxBody tx) =
    TxId
  . Crypto.UnsafeHash
  . SBS.toShort
  . recoverBytes
  $ tx

getTxId (ShelleyTxBody tx _) =
    TxId
  . Crypto.castHash
  . (\(Shelley.TxId txhash) -> txhash)
  . Shelley.txid @StandardShelley
  $ tx


-- ----------------------------------------------------------------------------
-- Transaction constituent types
--

data TxIn = TxIn TxId TxIx

deriving instance Eq TxIn
deriving instance Show TxIn

newtype TxIx = TxIx Word
  deriving stock (Eq, Ord, Show)
  deriving newtype (Enum)

data TxOut era = TxOut (Address era) (TxOutValue era)

deriving instance Eq (TxOut Byron)
deriving instance Eq (TxOut Shelley)
deriving instance Show (TxOut Byron)
deriving instance Show (TxOut Shelley)

toByronTxIn  :: TxIn -> Byron.TxIn
toByronTxIn (TxIn txid (TxIx txix)) =
    Byron.TxInUtxo (toByronTxId txid) (fromIntegral txix)

toByronTxOut :: TxOut Byron -> Maybe Byron.TxOut
toByronTxOut (TxOut (ByronAddress addr) (TxOutAdaOnly AdaOnlyInByronEra value)) =
    Byron.TxOut addr <$> toByronLovelace value

toByronTxOut (TxOut (ByronAddress _) (TxOutValue era _)) = case era of {}

toByronLovelace :: Lovelace -> Maybe Byron.Lovelace
toByronLovelace (Lovelace x) =
    case Byron.integerToLovelace x of
      Left  _  -> Nothing
      Right x' -> Just x'

toShelleyTxIn  :: TxIn -> Shelley.TxIn StandardShelley
toShelleyTxIn (TxIn txid (TxIx txix)) =
    Shelley.TxIn (toShelleyTxId txid) (fromIntegral txix)

toShelleyTxOut :: TxOut Shelley -> Shelley.TxOut StandardShelley
toShelleyTxOut (TxOut addr (TxOutAdaOnly _ value)) =
    Shelley.TxOut (toShelleyAddr addr) (toShelleyLovelace value)
toShelleyTxOut (TxOut _addr (TxOutValue evidence _)) = case evidence of {}


-- ----------------------------------------------------------------------------
-- Unsigned transactions
--

data TxBody era where

     ByronTxBody
       :: Annotated Byron.Tx ByteString
       -> TxBody Byron

     ShelleyTxBody
       :: Shelley.TxBody StandardShelley
       -> Maybe Shelley.MetaData
       -> TxBody Shelley

deriving instance Eq (TxBody Byron)
deriving instance Show (TxBody Byron)

deriving instance Eq (TxBody Shelley)
deriving instance Show (TxBody Shelley)

instance HasTypeProxy (TxBody Byron) where
    data AsType (TxBody Byron) = AsByronTxBody
    proxyToAsType _ = AsByronTxBody

instance HasTypeProxy (TxBody Shelley) where
    data AsType (TxBody Shelley) = AsShelleyTxBody
    proxyToAsType _ = AsShelleyTxBody


instance SerialiseAsCBOR (TxBody Byron) where
    serialiseToCBOR (ByronTxBody txbody) =
      recoverBytes txbody

    deserialiseFromCBOR AsByronTxBody bs = do
      ByronTxBody <$>
        CBOR.decodeFullAnnotatedBytes
          "Byron TxBody"
          CBOR.fromCBORAnnotated
          (LBS.fromStrict bs)

instance SerialiseAsCBOR (TxBody Shelley) where
    serialiseToCBOR (ShelleyTxBody txbody txmetadata) =
      CBOR.serializeEncoding' $
          CBOR.encodeListLen 2
       <> CBOR.toCBOR txbody
       <> CBOR.encodeNullMaybe CBOR.toCBOR txmetadata

    deserialiseFromCBOR AsShelleyTxBody bs =
      CBOR.decodeAnnotator
        "Shelley TxBody"
        decodeAnnotatedPair
        (LBS.fromStrict bs)
      where
        decodeAnnotatedPair :: CBOR.Decoder s (CBOR.Annotator (TxBody Shelley))
        decodeAnnotatedPair =  do
          CBOR.decodeListLenOf 2
          txbody     <- fromCBOR
          txmetadata <- CBOR.decodeNullMaybe fromCBOR
          return $ CBOR.Annotator $ \fbs ->
            ShelleyTxBody
              (flip CBOR.runAnnotator fbs txbody)
              (flip CBOR.runAnnotator fbs <$> txmetadata)


instance HasTextEnvelope (TxBody Byron) where
    textEnvelopeType _ = "TxUnsignedByron"

instance HasTextEnvelope (TxBody Shelley) where
    textEnvelopeType _ = "TxUnsignedShelley"


data ByronTxBodyConversionError =
       ByronTxBodyEmptyTxIns
     | ByronTxBodyEmptyTxOuts
     | ByronTxBodyLovelaceOverflow (TxOut Byron)
     deriving Show

makeByronTransaction :: [TxIn]
                     -> [TxOut Byron]
                     -> Either ByronTxBodyConversionError
                               (TxBody Byron)
makeByronTransaction ins outs = do
    ins'  <- NonEmpty.nonEmpty ins        ?! ByronTxBodyEmptyTxIns
    let ins'' = NonEmpty.map toByronTxIn ins'

    outs'  <- NonEmpty.nonEmpty outs      ?! ByronTxBodyEmptyTxOuts
    outs'' <- traverse
                (\out -> toByronTxOut out ?! ByronTxBodyLovelaceOverflow out)
                outs'
    return $
      ByronTxBody $
        reAnnotate $
          Annotated
            (Byron.UnsafeTx ins'' outs'' (Byron.mkAttributes ()))
            ()


data TxExtraContent =
     TxExtraContent {
       txMetadata        :: Maybe TxMetadata,
       txWithdrawals     :: [(StakeAddress, Lovelace)],
       txCertificates    :: [Certificate],
       txUpdateProposal  :: Maybe UpdateProposal
     }

txExtraContentEmpty :: TxExtraContent
txExtraContentEmpty =
    TxExtraContent {
      txMetadata        = Nothing,
      txWithdrawals     = [],
      txCertificates    = [],
      txUpdateProposal  = Nothing
    }

type TxFee = Lovelace
type TTL   = SlotNo

makeShelleyTransaction :: TxExtraContent
                       -> TTL
                       -> TxFee
                       -> [TxIn]
                       -> [TxOut Shelley]
                       -> TxBody Shelley
makeShelleyTransaction TxExtraContent {
                         txMetadata,
                         txWithdrawals,
                         txCertificates,
                         txUpdateProposal
                       } ttl fee ins outs =
    --TODO: validate the txins are not empty, and tx out coin values are in range
    ShelleyTxBody
      (Shelley.TxBody
        (Set.fromList (map toShelleyTxIn ins))
        (Seq.fromList (map toShelleyTxOut outs))
        (Seq.fromList [ cert | Certificate cert <- txCertificates ])
        (toShelleyWdrl txWithdrawals)
        (toShelleyLovelace fee)
        ttl
        (toShelleyUpdate <$> maybeToStrictMaybe txUpdateProposal)
        (toShelleyMetadataHash <$> maybeToStrictMaybe txMetadata))
      (toShelleyMetadata <$> txMetadata)
  where
    toShelleyUpdate (UpdateProposal p) = p

    toShelleyMetadata     (TxMetadataShelley m) = m
    toShelleyMetadataHash (TxMetadataShelley m) = Shelley.hashMetaData m

    toShelleyWdrl :: [(StakeAddress, Lovelace)] -> Shelley.Wdrl StandardShelley
    toShelleyWdrl wdrls =
        Shelley.Wdrl $
          Map.fromList
            [ (toShelleyStakeAddr stakeAddr, toShelleyLovelace value)
            | (stakeAddr, value) <- wdrls ]


-- ----------------------------------------------------------------------------
-- Signed transactions
--

data Tx era where

     ByronTx
       :: Byron.ATxAux ByteString
       -> Tx Byron

     ShelleyTx
       :: Shelley.Tx StandardShelley
       -> Tx Shelley

deriving instance Eq (Tx Byron)
deriving instance Show (Tx Byron)

deriving instance Eq (Tx Shelley)
deriving instance Show (Tx Shelley)

instance HasTypeProxy (Tx Byron) where
    data AsType (Tx Byron) = AsByronTx
    proxyToAsType _ = AsByronTx

instance HasTypeProxy (Tx Shelley) where
    data AsType (Tx Shelley) = AsShelleyTx
    proxyToAsType _ = AsShelleyTx


instance SerialiseAsCBOR (Tx Byron) where
    serialiseToCBOR (ByronTx tx) = CBOR.recoverBytes tx

    deserialiseFromCBOR AsByronTx bs =
      ByronTx <$>
        CBOR.decodeFullAnnotatedBytes "Byron Tx" fromCBOR (LBS.fromStrict bs)

instance SerialiseAsCBOR (Tx Shelley) where
    serialiseToCBOR (ShelleyTx tx) =
      CBOR.serialize' tx

    deserialiseFromCBOR AsShelleyTx bs =
      ShelleyTx <$>
        CBOR.decodeAnnotator "Shelley Tx" fromCBOR (LBS.fromStrict bs)

instance HasTextEnvelope (Tx Byron) where
    textEnvelopeType _ = "TxSignedByron"

instance HasTextEnvelope (Tx Shelley) where
    textEnvelopeType _ = "TxSignedShelley"


data Witness era where

     ByronKeyWitness
       :: Byron.TxInWitness
       -> Witness Byron

     ShelleyBootstrapWitness
       :: Shelley.BootstrapWitness StandardShelley
       -> Witness Shelley

     ShelleyKeyWitness
       :: Shelley.WitVKey Shelley.Witness StandardShelley
       -> Witness Shelley

     ShelleyScriptWitness
       :: Shelley.Script StandardShelley
       -> Witness Shelley

     AllegraScriptwitness
       :: Allegra.Timelock StandardAllegra
       -> Witness Allegra

     MaryScriptWitness
       :: Allegra.Timelock StandardMary
       -> Witness Mary

deriving instance Eq (Witness Byron)
deriving instance Show (Witness Byron)

deriving instance Eq (Witness Shelley)
deriving instance Show (Witness Shelley)

instance HasTypeProxy (Witness Byron) where
    data AsType (Witness Byron) = AsByronWitness
    proxyToAsType _ = AsByronWitness

instance HasTypeProxy (Witness Shelley) where
    data AsType (Witness Shelley) = AsShelleyWitness
    proxyToAsType _ = AsShelleyWitness

instance SerialiseAsCBOR (Witness Byron) where
    serialiseToCBOR (ByronKeyWitness wit) = CBOR.serialize' wit

    deserialiseFromCBOR AsByronWitness bs =
      ByronKeyWitness <$> CBOR.decodeFull' bs

instance SerialiseAsCBOR (Witness Shelley) where
    serialiseToCBOR = CBOR.serializeEncoding' . encodeShelleyWitness
      where
        encodeShelleyWitness :: Witness Shelley -> CBOR.Encoding
        encodeShelleyWitness (ShelleyKeyWitness    wit) =
            CBOR.encodeListLen 2 <> CBOR.encodeWord 0 <> toCBOR wit
        encodeShelleyWitness (ShelleyBootstrapWitness wit) =
            CBOR.encodeListLen 2 <> CBOR.encodeWord 1 <> toCBOR wit
        encodeShelleyWitness (ShelleyScriptWitness wit) =
            CBOR.encodeListLen 2
              <> CBOR.encodeWord 2
              -- We use 'WrappedMultiSig' here to support the legacy
              -- binary serialisation format for the @Script@ type from
              -- @cardano-ledger-specs@.
              --
              -- See the documentation of 'WrappedMultiSig' for more
              -- information.
              <> toCBOR (Legacy.WrappedMultiSig wit)

    deserialiseFromCBOR AsShelleyWitness bs =
        CBOR.decodeAnnotator "Shelley Witness"
                             decodeShelleyWitness (LBS.fromStrict bs)
      where
        decodeShelleyWitness :: CBOR.Decoder s (CBOR.Annotator (Witness Shelley))
        decodeShelleyWitness =  do
          CBOR.decodeListLenOf 2
          t <- CBOR.decodeWord
          case t of
            0 -> fmap (fmap ShelleyKeyWitness) fromCBOR
            1 -> fmap (fmap ShelleyBootstrapWitness) fromCBOR
            -- We use 'WrappedMultiSig' here to support the legacy binary
            -- serialisation format for the @Script@ type from
            -- @cardano-ledger-specs@.
            --
            -- See the documentation of 'WrappedMultiSig' for more
            -- information.
            2 -> fmap (fmap (ShelleyScriptWitness . Legacy.unWrappedMultiSig)) fromCBOR
            _ -> CBOR.cborError $ CBOR.DecoderErrorUnknownTag
                                    "Shelley Witness" (fromIntegral t)

instance HasTextEnvelope (Witness Byron) where
    textEnvelopeType _ = "TxWitnessByron"

instance HasTextEnvelope (Witness Shelley) where
    textEnvelopeType _ = "TxWitnessShelley"


getTxBody :: Tx era -> TxBody era
getTxBody (ByronTx Byron.ATxAux { Byron.aTaTx = txbody }) =
    ByronTxBody txbody

getTxBody (ShelleyTx Shelley.Tx {
                       Shelley._body     = txbody,
                       Shelley._metadata = txmetadata
                     }) =
    ShelleyTxBody txbody (strictMaybeToMaybe txmetadata)


getTxWitnesses :: Tx era -> [Witness era]
getTxWitnesses (ByronTx Byron.ATxAux { Byron.aTaWitness = witnesses }) =
    map ByronKeyWitness
  . Vector.toList
  . unAnnotated
  $ witnesses

getTxWitnesses (ShelleyTx Shelley.Tx {
                       Shelley._witnessSet =
                         Shelley.WitnessSet
                           addrWits
                           msigWits
                           bootWits
                     }) =
    map ShelleyBootstrapWitness (Set.elems bootWits)
 ++ map ShelleyKeyWitness       (Set.elems addrWits)
 ++ map ShelleyScriptWitness    (Map.elems msigWits)


makeSignedTransaction :: [Witness era]
                      -> TxBody era
                      -> Tx era
makeSignedTransaction witnesses (ByronTxBody txbody) =
    ByronTx
  . Byron.annotateTxAux
  $ Byron.mkTxAux
      (unAnnotated txbody)
      (Vector.fromList (map selectByronWitness witnesses))
  where
    selectByronWitness :: Witness Byron -> Byron.TxInWitness
    selectByronWitness (ByronKeyWitness w) = w

makeSignedTransaction witnesses (ShelleyTxBody txbody txmetadata) =
    ShelleyTx $
      Shelley.Tx
        txbody
        (Shelley.WitnessSet
          (Set.fromList [ w | ShelleyKeyWitness w <- witnesses ])
          (Map.fromList [ (Shelley.hashMultiSigScript sw, sw)
                        | ShelleyScriptWitness sw <- witnesses ])
          (Set.fromList [ w | ShelleyBootstrapWitness w <- witnesses ]))
        (maybeToStrictMaybe txmetadata)

makeByronKeyWitness :: NetworkId
                    -> TxBody Byron
                    -> SigningKey ByronKey
                    -> Witness Byron
makeByronKeyWitness nw (ByronTxBody txbody) =
    let txhash :: Byron.Hash Byron.Tx
        txhash = Byron.hashDecoded txbody

        pm :: Byron.ProtocolMagicId
        pm = toByronProtocolMagicId nw

        -- To allow sharing of the txhash computation across many signatures we
        -- define and share the txhash outside the lambda for the signing key:
     in \(ByronSigningKey sk) ->
        ByronKeyWitness $
          Byron.VKWitness
            (Byron.toVerification sk)
            (Byron.sign pm Byron.SignTx sk (Byron.TxSigData txhash))

-- | Either a network ID or a Byron address to be used in constructing a
-- Shelley bootstrap witness.
data WitnessNetworkIdOrByronAddress
  = WitnessNetworkId !NetworkId
  -- ^ Network ID.
  --
  -- If this value is used in the construction of a Shelley bootstrap witness,
  -- the result will not consist of a derivation path. If that is required,
  -- specify a 'WitnessByronAddress' value instead.
  | WitnessByronAddress !(Address Byron)
  -- ^ Byron address.
  --
  -- If this value is used in the construction of a Shelley bootstrap witness,
  -- both the network ID and derivation path will be extracted from the
  -- address and used in the construction of the witness.

makeShelleyBootstrapWitness :: WitnessNetworkIdOrByronAddress
                            -> TxBody Shelley
                            -> SigningKey ByronKey
                            -> Witness Shelley
makeShelleyBootstrapWitness nwOrAddr (ShelleyTxBody txbody _) (ByronSigningKey sk) =
    ShelleyBootstrapWitness $
      -- Byron era witnesses were weird. This reveals all that weirdness.
      Shelley.BootstrapWitness {
        Shelley.bwKey        = vk,
        Shelley.bwSig        = signature,
        Shelley.bwChainCode  = chainCode,
        Shelley.bwAttributes = attributes
      }
  where
    -- Starting with the easy bits: we /can/ convert the Byron verification key
    -- to a the pair of a Shelley verification key plus the chain code.
    --
    (vk, chainCode) = Shelley.unpackByronVKey (Byron.toVerification sk)

    -- Now the hairy bits.
    --
    -- Byron era signing keys were all /extended/ ed25519 keys. We have to
    -- produce a signature using this extended signing key directly. They
    -- /cannot/ be converted to a plain (non-extended) signing keys. Since we
    -- now support extended signing keys for the Shelley too, we are able to
    -- reuse that here.
    --
    signature :: Shelley.SignedDSIGN StandardCrypto
                  (Shelley.Hash StandardCrypto Shelley.EraIndependentTxBody)
    signature = makeShelleySignature
                  txhash
                  -- Make the signature with the extended key directly:
                  (ShelleyExtendedSigningKey (Byron.unSigningKey sk))

    txhash :: Shelley.Hash StandardCrypto Shelley.EraIndependentTxBody
    txhash = Shelley.eraIndTxBodyHash txbody

    -- And finally we need to provide the extra suffix bytes necessary to
    -- reconstruct the mini-Merkel tree that is a Byron address. The suffix
    -- bytes are the serialised address attributes.
    attributes =
      CBOR.serialize' $
        Byron.mkAttributes Byron.AddrAttributes {
          Byron.aaVKDerivationPath = derivationPath,
          Byron.aaNetworkMagic     = networkMagic
        }

    -- The 'WitnessNetworkIdOrByronAddress' value converted to an 'Either'.
    eitherNwOrAddr :: Either NetworkId (Address Byron)
    eitherNwOrAddr =
      case nwOrAddr of
        WitnessNetworkId nw -> Left nw
        WitnessByronAddress addr -> Right addr

    unByronAddr :: Address Byron -> Byron.Address
    unByronAddr (ByronAddress addr) = addr

    unAddrAttrs :: Address Byron -> Byron.AddrAttributes
    unAddrAttrs = Byron.attrData . Byron.addrAttributes . unByronAddr

    derivationPath :: Maybe Byron.HDAddressPayload
    derivationPath =
      either
        (const Nothing)
        (Byron.aaVKDerivationPath . unAddrAttrs)
        eitherNwOrAddr

    networkMagic :: Byron.NetworkMagic
    networkMagic =
      either
        toByronNetworkMagic
        (Byron.aaNetworkMagic . unAddrAttrs)
        eitherNwOrAddr

data ShelleyWitnessSigningKey =
       WitnessPaymentKey         (SigningKey PaymentKey)
     | WitnessPaymentExtendedKey (SigningKey PaymentExtendedKey)
     | WitnessStakeKey           (SigningKey StakeKey)
     | WitnessStakeExtendedKey   (SigningKey StakeExtendedKey)
     | WitnessStakePoolKey       (SigningKey StakePoolKey)
     | WitnessGenesisKey         (SigningKey GenesisKey)
     | WitnessGenesisExtendedKey (SigningKey GenesisExtendedKey)
     | WitnessGenesisDelegateKey (SigningKey GenesisDelegateKey)
     | WitnessGenesisDelegateExtendedKey
                                 (SigningKey GenesisDelegateExtendedKey)
     | WitnessGenesisUTxOKey     (SigningKey GenesisUTxOKey)


makeShelleyKeyWitness :: TxBody Shelley
                      -> ShelleyWitnessSigningKey
                      -> Witness Shelley
makeShelleyKeyWitness (ShelleyTxBody txbody _) =
    let txhash :: Shelley.Hash StandardCrypto Shelley.EraIndependentTxBody
        txhash = Shelley.hashAnnotated txbody

        -- To allow sharing of the txhash computation across many signatures we
        -- define and share the txhash outside the lambda for the signing key:
     in \wsk ->
        let sk        = toShelleySigningKey wsk
            vk        = getShelleyKeyWitnessVerificationKey sk
            signature = makeShelleySignature txhash sk
         in ShelleyKeyWitness $
              Shelley.WitVKey vk signature


-- | We support making key witnesses with both normal and extended signing keys.
--
data ShelleySigningKey =
       -- | A normal ed25519 signing key
       ShelleyNormalSigningKey   (Shelley.SignKeyDSIGN StandardCrypto)

       -- | An extended ed25519 signing key
     | ShelleyExtendedSigningKey Crypto.HD.XPrv


toShelleySigningKey :: ShelleyWitnessSigningKey -> ShelleySigningKey
toShelleySigningKey key = case key of
  WitnessPaymentKey     (PaymentSigningKey     sk) -> ShelleyNormalSigningKey sk
  WitnessStakeKey       (StakeSigningKey       sk) -> ShelleyNormalSigningKey sk
  WitnessStakePoolKey   (StakePoolSigningKey   sk) -> ShelleyNormalSigningKey sk
  WitnessGenesisKey     (GenesisSigningKey     sk) -> ShelleyNormalSigningKey sk
  WitnessGenesisUTxOKey (GenesisUTxOSigningKey sk) -> ShelleyNormalSigningKey sk
  WitnessGenesisDelegateKey (GenesisDelegateSigningKey sk) ->
    ShelleyNormalSigningKey sk

  -- The cases for extended keys
  WitnessPaymentExtendedKey (PaymentExtendedSigningKey sk) ->
    ShelleyExtendedSigningKey sk

  WitnessStakeExtendedKey (StakeExtendedSigningKey sk) ->
    ShelleyExtendedSigningKey sk

  WitnessGenesisExtendedKey (GenesisExtendedSigningKey sk) ->
    ShelleyExtendedSigningKey sk

  WitnessGenesisDelegateExtendedKey (GenesisDelegateExtendedSigningKey sk) ->
    ShelleyExtendedSigningKey sk


getShelleyKeyWitnessVerificationKey
  :: ShelleySigningKey
  -> Shelley.VKey Shelley.Witness StandardCrypto
getShelleyKeyWitnessVerificationKey (ShelleyNormalSigningKey sk) =
      (Shelley.coerceKeyRole :: Shelley.VKey Shelley.Payment StandardCrypto
                             -> Shelley.VKey Shelley.Witness StandardCrypto)
    . (\(PaymentVerificationKey vk) -> vk)
    . getVerificationKey
    . PaymentSigningKey
    $ sk

getShelleyKeyWitnessVerificationKey (ShelleyExtendedSigningKey sk) =
      (Shelley.coerceKeyRole :: Shelley.VKey Shelley.Payment StandardCrypto
                             -> Shelley.VKey Shelley.Witness StandardCrypto)
    . (\(PaymentVerificationKey vk) -> vk)
    . (castVerificationKey :: VerificationKey PaymentExtendedKey
                           -> VerificationKey PaymentKey)
    . getVerificationKey
    . PaymentExtendedSigningKey
    $ sk


makeShelleySignature
  :: Crypto.SignableRepresentation tosign
  => tosign
  -> ShelleySigningKey
  -> Shelley.SignedDSIGN StandardCrypto tosign
makeShelleySignature tosign (ShelleyNormalSigningKey sk) =
    Crypto.signedDSIGN () tosign sk

makeShelleySignature tosign (ShelleyExtendedSigningKey sk) =
    fromXSignature $
      Crypto.HD.sign
        BS.empty  -- passphrase for (unused) in-memory encryption
        sk
        (Crypto.getSignableRepresentation tosign)
  where
    fromXSignature :: Crypto.HD.XSignature
                   -> Shelley.SignedDSIGN StandardCrypto b
    fromXSignature =
        Crypto.SignedDSIGN
      . fromMaybe impossible
      . Crypto.rawDeserialiseSigDSIGN
      . Crypto.HD.unXSignature

    impossible =
      error "makeShelleyKeyWitnessSignature: byron and shelley signature sizes do not match"


makeScriptWitness :: forall era. Script era -> Witness era
makeScriptWitness (ShelleyScript s) = ShelleyScriptWitness s
makeScriptWitness (AllegraScript s) = AllegraScriptwitness s
makeScriptWitness (MaryScript    s) = MaryScriptWitness s

-- order of signing keys must match txins
signByronTransaction :: NetworkId
                     -> TxBody Byron
                     -> [SigningKey ByronKey]
                     -> Tx Byron
signByronTransaction nw txbody sks =
    makeSignedTransaction witnesses txbody
  where
    witnesses = map (makeByronKeyWitness nw txbody) sks

-- signing keys is a set
signShelleyTransaction :: TxBody Shelley
                       -> [ShelleyWitnessSigningKey]
                       -> Tx Shelley
signShelleyTransaction txbody sks =
    makeSignedTransaction witnesses txbody
  where
    witnesses = map (makeShelleyKeyWitness txbody) sks


-- ----------------------------------------------------------------------------
-- Transaction fees
--

-- | For a concrete fully-constructed transaction, determine the minimum fee
-- that it needs to pay.
--
-- This function is simple, but if you are doing input selection then you
-- probably want to consider estimateTransactionFee.
--
transactionFee :: Natural -- ^ The fixed tx fee
               -> Natural -- ^ The tx fee per byte
               -> Tx Shelley
               -> Lovelace
transactionFee txFeeFixed txFeePerByte (ShelleyTx tx) =
    Lovelace (a * x + b)
  where
    a = toInteger txFeePerByte
    x = Shelley.txsize tx
    b = toInteger txFeeFixed

--TODO: in the Byron case the per-byte is non-integral, would need different
-- parameters. e.g. a new data type for fee params, Byron vs Shelley

-- | This can estimate what the transaction fee will be, based on a starting
-- base transaction, plus the numbers of the additional components of the
-- transaction that may be added.
--
-- So for example with wallet coin selection, the base transaction should
-- contain all the things not subject to coin selection (such as script inputs,
-- metadata, withdrawals, certs etc)
--
estimateTransactionFee :: NetworkId
                       -> Natural -- ^ The fixed tx fee
                       -> Natural -- ^ The tx fee per byte
                       -> Tx Shelley
                       -> Int -- ^ The number of extra UTxO transaction inputs
                       -> Int -- ^ The number of extra transaction outputs
                       -> Int -- ^ The number of extra Shelley key witnesses
                       -> Int -- ^ The number of extra Byron key witnesses
                       -> Lovelace
estimateTransactionFee nw txFeeFixed txFeePerByte (ShelleyTx tx) =
    let Lovelace baseFee = transactionFee txFeeFixed txFeePerByte (ShelleyTx tx)
     in \nInputs nOutputs nShelleyKeyWitnesses nByronKeyWitnesses ->

        --TODO: this is fragile. Move something like this to the ledger and
        -- make it robust, based on the txsize calculation.
        let extraBytes :: Int
            extraBytes = nInputs               * sizeInput
                       + nOutputs              * sizeOutput
                       + nByronKeyWitnesses    * sizeByronKeyWitnesses
                       + nShelleyKeyWitnesses  * sizeShelleyKeyWitnesses

         in Lovelace (baseFee + toInteger txFeePerByte * toInteger extraBytes)
  where
    sizeInput               = smallArray + uint + hashObj
    sizeOutput              = smallArray + uint + address
    sizeByronKeyWitnesses   = smallArray + keyObj + sigObj + ccodeObj + attrsObj
    sizeShelleyKeyWitnesses = smallArray + keyObj + sigObj

    smallArray  = 1
    uint        = 5

    hashObj     = 2 + hashLen
    hashLen     = 32

    keyObj      = 2 + keyLen
    keyLen      = 32

    sigObj      = 2 + sigLen
    sigLen      = 64

    ccodeObj    = 2 + ccodeLen
    ccodeLen    = 32

    address     = 2 + addrHeader + 2 * addrHashLen
    addrHeader  = 1
    addrHashLen = 28

    attrsObj    = 2 + BS.length attributes
    attributes  = CBOR.serialize' $
                    Byron.mkAttributes Byron.AddrAttributes {
                      Byron.aaVKDerivationPath = Nothing,
                      Byron.aaNetworkMagic     = toByronNetworkMagic nw
                    }


-- ----------------------------------------------------------------------------
-- Operational certificates
--

data OperationalCertificate =
     OperationalCertificate
       !(Shelley.OCert StandardCrypto)
       !(VerificationKey StakePoolKey)
  deriving (Eq, Show)
  deriving anyclass SerialiseAsCBOR

data OperationalCertificateIssueCounter =
     OperationalCertificateIssueCounter
       !Word64
       !(VerificationKey StakePoolKey) -- For consistency checking
  deriving (Eq, Show)
  deriving anyclass SerialiseAsCBOR

instance ToCBOR OperationalCertificate where
    toCBOR (OperationalCertificate ocert vkey) =
      toCBOR (CBOR.CBORGroup ocert, vkey)

instance FromCBOR OperationalCertificate where
    fromCBOR = do
      (CBOR.CBORGroup ocert, vkey) <- fromCBOR
      return (OperationalCertificate ocert vkey)

instance ToCBOR OperationalCertificateIssueCounter where
    toCBOR (OperationalCertificateIssueCounter counter vkey) =
      toCBOR (counter, vkey)

instance FromCBOR OperationalCertificateIssueCounter where
    fromCBOR = do
      (counter, vkey) <- fromCBOR
      return (OperationalCertificateIssueCounter counter vkey)

instance HasTypeProxy OperationalCertificate where
    data AsType OperationalCertificate = AsOperationalCertificate
    proxyToAsType _ = AsOperationalCertificate

instance HasTypeProxy OperationalCertificateIssueCounter where
    data AsType OperationalCertificateIssueCounter = AsOperationalCertificateIssueCounter
    proxyToAsType _ = AsOperationalCertificateIssueCounter

instance HasTextEnvelope OperationalCertificate where
    textEnvelopeType _ = "NodeOperationalCertificate"

instance HasTextEnvelope OperationalCertificateIssueCounter where
    textEnvelopeType _ = "NodeOperationalCertificateIssueCounter"

data OperationalCertIssueError =
       -- | The stake pool verification key expected for the
       -- 'OperationalCertificateIssueCounter' does not match the signing key
       -- supplied for signing.
       --
       -- Order: pool vkey expected, pool skey supplied
       --
       OperationalCertKeyMismatch (VerificationKey StakePoolKey)
                                  (VerificationKey StakePoolKey)
  deriving Show

instance Error OperationalCertIssueError where
    displayError (OperationalCertKeyMismatch _counterKey _signingKey) =
      "Key mismatch: the signing key does not match the one that goes with the counter"
      --TODO: include key ids

issueOperationalCertificate :: VerificationKey KesKey
                            -> Either (SigningKey StakePoolKey)
                                      (SigningKey GenesisDelegateExtendedKey)
                               --TODO: this may be better with a type that
                               -- captured the three (four?) choices, stake pool
                               -- or genesis delegate, extended or normal.
                            -> Shelley.KESPeriod
                            -> OperationalCertificateIssueCounter
                            -> Either OperationalCertIssueError
                                      (OperationalCertificate,
                                      OperationalCertificateIssueCounter)
issueOperationalCertificate (KesVerificationKey kesVKey)
                            skey
                            kesPeriod
                            (OperationalCertificateIssueCounter counter poolVKey)
    | poolVKey /= poolVKey'
    = Left (OperationalCertKeyMismatch poolVKey poolVKey')

    | otherwise
    = Right (OperationalCertificate ocert poolVKey,
            OperationalCertificateIssueCounter (succ counter) poolVKey)
  where
    poolVKey' :: VerificationKey StakePoolKey
    poolVKey' = either getVerificationKey (convert . getVerificationKey) skey
      where
        convert :: VerificationKey GenesisDelegateExtendedKey
                -> VerificationKey StakePoolKey
        convert = (castVerificationKey :: VerificationKey GenesisDelegateKey
                                       -> VerificationKey StakePoolKey)
                . (castVerificationKey :: VerificationKey GenesisDelegateExtendedKey
                                       -> VerificationKey GenesisDelegateKey)

    ocert     :: Shelley.OCert StandardCrypto
    ocert     = Shelley.OCert kesVKey counter kesPeriod signature

    signature :: Shelley.SignedDSIGN
                   StandardCrypto
                   (Shelley.OCertSignable StandardCrypto)
    signature = makeShelleySignature
                  (Shelley.OCertSignable kesVKey counter kesPeriod)
                  skey'
      where
        skey' :: ShelleySigningKey
        skey' = case skey of
                  Left (StakePoolSigningKey poolSKey) ->
                    ShelleyNormalSigningKey poolSKey
                  Right (GenesisDelegateExtendedSigningKey delegSKey) ->
                    ShelleyExtendedSigningKey delegSKey


-- ----------------------------------------------------------------------------
-- Node IPC protocols
--

data ByronMode
data ShelleyMode
data CardanoMode

data LocalNodeConnectInfo mode block =
     LocalNodeConnectInfo {
       localNodeSocketPath    :: FilePath,
       localNodeNetworkId     :: NetworkId,
       localNodeConsensusMode :: NodeConsensusMode mode block
     }

data NodeConsensusMode mode block where

     ByronMode
       :: Byron.EpochSlots
       -> NodeConsensusMode ByronMode ByronBlockHFC

     ShelleyMode
       :: NodeConsensusMode ShelleyMode (ShelleyBlockHFC StandardShelley)

     CardanoMode
       :: Byron.EpochSlots
       -> NodeConsensusMode CardanoMode (CardanoBlock StandardCrypto)


withNodeProtocolClient
  :: NodeConsensusMode mode block
  -> (   (SerialiseNodeToClientConstraints block,
          SupportedNetworkProtocolVersion block)
      => ProtocolClient block (BlockProtocol block) -> a)
  -> a
withNodeProtocolClient (ByronMode epochSlots) f =
    f (mkNodeClientProtocolByron epochSlots)

withNodeProtocolClient ShelleyMode f = f mkNodeClientProtocolShelley

withNodeProtocolClient (CardanoMode epochSlots) f =
    f (mkNodeClientProtocolCardano epochSlots)

data LocalNodeClientProtocols block =
     LocalNodeClientProtocols {
       localChainSyncClient
         :: Maybe (ChainSyncClient
                    block
                    (Point block)
                    (Tip block)
                    IO ())

     , localTxSubmissionClient
         :: Maybe (LocalTxSubmissionClient
                    (GenTx block)
                    (ApplyTxErr block)
                    IO ())

     , localStateQueryClient
         :: Maybe (LocalStateQueryClient
                    block
                    (Point block)
                    (Query block)
                    IO ())
     }

nullLocalNodeClientProtocols :: LocalNodeClientProtocols block
nullLocalNodeClientProtocols =
    LocalNodeClientProtocols {
      localChainSyncClient    = Nothing,
      localTxSubmissionClient = Nothing,
      localStateQueryClient   = Nothing
    }


-- | Establish a connection to a node and execute the given set of protocol
-- handlers.
--
connectToLocalNode :: forall mode block.
                      (ShowProxy block, ShowProxy (ApplyTxErr block),
                       ShowProxy (Query block), ShowProxy (GenTx block),
                       ShowQuery (Query block))
                       --TODO: too many constraints! we should pass
                       -- a single protocol to run, not all of them, until we
                       -- have the more flexible interface to run any combo
                   => LocalNodeConnectInfo mode block
                   -> LocalNodeClientProtocols block
                   -> IO ()
connectToLocalNode LocalNodeConnectInfo {
                     localNodeSocketPath    = path,
                     localNodeNetworkId     = network,
                     localNodeConsensusMode = mode
                   } clientptcls =
    withIOManager $ \iomgr ->
      withNodeProtocolClient mode $ \ptcl ->
      connectTo
        (localSnocket iomgr path)
        NetworkConnectTracers {
          nctMuxTracer       = nullTracer,
          nctHandshakeTracer = nullTracer
        }
        (foldMapVersions
            (\(version, blockVersion) ->
                versionedNodeToClientProtocols
                     version
                     NodeToClientVersionData {
                       networkMagic = toNetworkMagic network
                     }
                     (\_conn _runOrStop -> protocols ptcl blockVersion))
            (Map.toList (supportedNodeToClientVersions proxy)))
        path
  where
    proxy :: Proxy block
    proxy = Proxy

    protocols :: SerialiseNodeToClientConstraints block
              => ProtocolClient block (BlockProtocol block)
              -> BlockNodeToClientVersion block
              -> NodeToClientProtocols InitiatorMode LBS.ByteString IO () Void
    protocols ptcl clientVersion =
      let Codecs {
              cChainSyncCodec
            , cTxSubmissionCodec
            , cStateQueryCodec
            } = clientCodecs (pClientInfoCodecConfig (protocolClientInfo ptcl))
                             clientVersion

          LocalNodeClientProtocols {
            localChainSyncClient,
            localTxSubmissionClient,
            localStateQueryClient
          } = clientptcls

       in NodeToClientProtocols {
            localChainSyncProtocol =
              InitiatorProtocolOnly $
                MuxPeer
                  nullTracer
                  cChainSyncCodec
                  (maybe chainSyncPeerNull
                         chainSyncClientPeer
                         localChainSyncClient)

          , localTxSubmissionProtocol =
              InitiatorProtocolOnly $
                MuxPeer
                  nullTracer
                  cTxSubmissionCodec
                  (maybe localTxSubmissionPeerNull
                         localTxSubmissionClientPeer
                         localTxSubmissionClient)

          , localStateQueryProtocol =
              InitiatorProtocolOnly $
                MuxPeer
                  nullTracer
                  cStateQueryCodec
                  (maybe localStateQueryPeerNull
                         localStateQueryClientPeer
                         localStateQueryClient)
          }


--TODO: change this query to be just a protocol client handler to be used with
-- connectToLocalNode. This would involve changing connectToLocalNode to be
-- able to return protocol handler results properly.

-- | Establish a connection to a node and execute a single query using the
-- local state query protocol.
--
queryNodeLocalState :: forall mode block result.
                       (ShowProxy block, ShowProxy (ApplyTxErr block),
                        ShowProxy (Query block), ShowProxy (GenTx block),
                        ShowQuery (Query block))
                    => LocalNodeConnectInfo mode block
                    -> (Point block, Query block result)
                    -> IO (Either AcquireFailure result)
queryNodeLocalState connctInfo pointAndQuery = do
    resultVar <- newEmptyTMVarIO
    connectToLocalNode
      connctInfo
      nullLocalNodeClientProtocols {
        localStateQueryClient =
          Just (localStateQuerySingle resultVar pointAndQuery)
      }
    atomically (takeTMVar resultVar)
  where
    localStateQuerySingle
      :: TMVar (Either AcquireFailure result)
      -> (Point block, Query block result)
      -> LocalStateQueryClient block (Point block) (Query block) IO ()
    localStateQuerySingle resultVar (point, query) =
      LocalStateQueryClient $ pure $
        SendMsgAcquire point $
        ClientStAcquiring {
          recvMsgAcquired =
            SendMsgQuery query $
            ClientStQuerying {
              recvMsgResult = \result -> do
                --TODO: return the result via the SendMsgDone rather than
                -- writing into an mvar
                atomically $ putTMVar resultVar (Right result)
                pure $ SendMsgRelease $
                  pure $ StateQuery.SendMsgDone ()
            }
        , recvMsgFailure = \failure -> do
            --TODO: return the result via the SendMsgDone rather than
            -- writing into an mvar
            atomically $ putTMVar resultVar (Left failure)
            pure $ StateQuery.SendMsgDone ()
        }

submitTxToNodeLocal :: forall mode block.
                       (ShowProxy block, ShowProxy (ApplyTxErr block),
                        ShowProxy (Query block), ShowProxy (GenTx block),
                        ShowQuery (Query block))
                    => LocalNodeConnectInfo mode block
                    -> GenTx block
                    -> IO (SubmitResult (ApplyTxErr block))
submitTxToNodeLocal connctInfo tx = do
    resultVar <- newEmptyTMVarIO
    connectToLocalNode
      connctInfo
      nullLocalNodeClientProtocols {
        localTxSubmissionClient =
          Just (localTxSubmissionClientSingle resultVar)
      }
    atomically (takeTMVar resultVar)
  where
    localTxSubmissionClientSingle
      :: TMVar (SubmitResult (ApplyTxErr block))
      -> LocalTxSubmissionClient (GenTx block) (ApplyTxErr block) IO ()
    localTxSubmissionClientSingle resultVar =
        LocalTxSubmissionClient $
        pure $ SendMsgSubmitTx tx $ \result -> do
        atomically $ putTMVar resultVar result
        pure (TxSubmission.SendMsgDone ())



-- | Compute the 'TxIn' of the initial UTxO pseudo-transaction corresponding
-- to the given address in the genesis initial funds.
--
-- The Shelley initial UTxO is constructed from the 'sgInitialFunds' which
-- is not a full UTxO but just a map from addresses to coin values.
--
-- This gets turned into a UTxO by making a pseudo-transaction for each address,
-- with the 0th output being the coin value. So to spend from the initial UTxO
-- we need this same 'TxIn' to use as an input to the spending transaction.
--
genesisUTxOPseudoTxIn :: NetworkId -> Hash GenesisUTxOKey -> TxIn
genesisUTxOPseudoTxIn nw (GenesisUTxOKeyHash kh) =
    --TODO: should handle Byron UTxO case too.
    fromShelleyTxIn (Shelley.initialFundsPseudoTxIn addr)
  where
    addr = Shelley.Addr
             (toShelleyNetwork nw)
             (Shelley.KeyHashObj kh)
             Shelley.StakeRefNull

    fromShelleyTxIn  :: Shelley.TxIn StandardShelley -> TxIn
    fromShelleyTxIn (Shelley.TxIn txid txix) =
        TxIn (fromShelleyTxId txid) (TxIx (fromIntegral txix))

    fromShelleyTxId :: Shelley.TxId StandardShelley -> TxId
    fromShelleyTxId (Shelley.TxId h) =
        TxId (Crypto.castHash h)

