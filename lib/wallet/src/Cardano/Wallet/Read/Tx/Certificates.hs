{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}

-- |
-- Copyright: © 2020-2022 IOHK
-- License: Apache-2.0
--
-- Raw certificate data extraction from 'Tx'
--

module Cardano.Wallet.Read.Tx.Certificates
    ( CertificatesType
    , Certificates (..)
    , getEraCertificates
    )
    where

import Prelude

import Cardano.Api
    ( AllegraEra
    , AlonzoEra
    , BabbageEra
    , ByronEra
    , ConwayEra
    , MaryEra
    , ShelleyEra
    )
import Cardano.Ledger.Core
    ( bodyTxL )
import Cardano.Ledger.Crypto
    ( StandardCrypto )
import Cardano.Ledger.Shelley.TxBody
    ( DCert, certsTxBodyL )
import Cardano.Wallet.Read.Eras
    ( EraFun (..) )
import Cardano.Wallet.Read.Tx
    ( Tx (..) )
import Cardano.Wallet.Read.Tx.Eras
    ( onTx )
import Control.Lens
    ( (^.) )
import Data.Sequence.Strict
    ( StrictSeq )

type family CertificatesType era where
    CertificatesType ByronEra = ()
    CertificatesType ShelleyEra = StrictSeq (DCert StandardCrypto)
    CertificatesType AllegraEra = StrictSeq (DCert StandardCrypto)
    CertificatesType MaryEra = StrictSeq (DCert StandardCrypto)
    CertificatesType AlonzoEra = StrictSeq (DCert StandardCrypto)
    CertificatesType BabbageEra = StrictSeq (DCert StandardCrypto)
    CertificatesType ConwayEra = StrictSeq (DCert StandardCrypto)

newtype Certificates era = Certificates (CertificatesType era)

deriving instance Show (CertificatesType era) => Show (Certificates era)
deriving instance Eq (CertificatesType era) => Eq (Certificates era)

-- | Extract certificates from a 'Tx' in any era.
getEraCertificates :: EraFun Tx Certificates
getEraCertificates = EraFun
    { byronFun = \_ -> Certificates ()
    , shelleyFun = shellyCertificates
    , allegraFun = shellyCertificates
    , maryFun = shellyCertificates
    , alonzoFun = shellyCertificates
    , babbageFun = shellyCertificates
    , conwayFun = shellyCertificates
    }
    where
    shellyCertificates = onTx
        $ \tx -> Certificates $ tx ^. bodyTxL . certsTxBodyL
