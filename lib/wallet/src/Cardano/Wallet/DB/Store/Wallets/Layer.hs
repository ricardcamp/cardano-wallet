{-# LANGUAGE GADTs #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE TypeFamilies #-}

{- |
Copyright: © 2022 IOHK
License: Apache-2.0

Implementation of a 'QueryStore' for 'TxWalletsHistory'.
-}
module Cardano.Wallet.DB.Store.Wallets.Layer
    ( QueryTxWalletsHistory (..)
    , QueryStoreTxWalletsHistory
    , newQueryStoreTxWalletsHistory
    ) where

import Prelude

import Cardano.Wallet.DB.Sqlite.Schema
    ( CBOR, TxMeta (..) )
import Cardano.Wallet.DB.Sqlite.Types
    ( TxId (..) )
import Cardano.Wallet.DB.Store.Meta.Model
    ( TxMetaHistory (relations) )
import Cardano.Wallet.DB.Store.QueryStore
    ( QueryStore (..) )
import Cardano.Wallet.DB.Store.Transactions.Model
    ( TxRelation )
import Cardano.Wallet.DB.Store.Wallets.Model
    ( DeltaTxWalletsHistory (..) )
import Cardano.Wallet.DB.Store.Wallets.Store
    ( mkStoreTxWalletsHistory, mkStoreWalletsMeta )
import Data.DBVar
    ( Store (..), newCachedStore )
import Data.Foldable
    ( toList )
import Data.Word
    ( Word32 )
import Database.Persist.Sql
    ( SqlPersistT )

import qualified Cardano.Wallet.DB.Store.Transactions.Layer as TxSet
import qualified Cardano.Wallet.Primitive.Types as W
import qualified Cardano.Wallet.Primitive.Types.Tx.TxOut as W
import qualified Data.Map.Strict as Map

{-----------------------------------------------------------------------------
    Query type
------------------------------------------------------------------------------}
data QueryTxWalletsHistory b where
    GetByTxId :: TxId -> QueryTxWalletsHistory (Maybe (Either TxRelation CBOR))
    GetTxOut :: (TxId, Word32) -> QueryTxWalletsHistory (Maybe W.TxOut)
    One :: W.WalletId -> TxId -> QueryTxWalletsHistory (Maybe TxMeta)
    All :: W.WalletId -> QueryTxWalletsHistory [TxMeta]

{-----------------------------------------------------------------------------
    Query Store type
------------------------------------------------------------------------------}
type QueryStoreTxWalletsHistory =
    QueryStore (SqlPersistT IO) QueryTxWalletsHistory DeltaTxWalletsHistory

newQueryStoreTxWalletsHistory
    :: forall m. m ~ SqlPersistT IO
    => m QueryStoreTxWalletsHistory
newQueryStoreTxWalletsHistory = do
    let txsQueryStore = TxSet.mkQueryStoreTxSet

    let storeTransactions = store txsQueryStore
    storeWalletsMeta <- newCachedStore mkStoreWalletsMeta
    let storeTxWalletsHistory = mkStoreTxWalletsHistory
            storeTransactions       -- on disk
            storeWalletsMeta        -- in memory

    let readAllMetas :: W.WalletId -> m [TxMeta]
        readAllMetas wid = do
            Right wmetas <- loadS storeWalletsMeta
            pure
                . maybe [] (toList . relations)
                $ Map.lookup wid wmetas

        query :: forall a. QueryTxWalletsHistory a -> SqlPersistT IO a
        query = \case
            GetByTxId txid -> do
                queryS txsQueryStore $ TxSet.GetByTxId txid
            GetTxOut key -> do
                queryS txsQueryStore $ TxSet.GetTxOut key

            One wid txid -> do
                Right wmetas <- loadS storeWalletsMeta
                pure $ do
                    metas <- Map.lookup wid wmetas
                    Map.lookup txid . relations $ metas
            All wid ->
                readAllMetas wid

    pure QueryStore
        { queryS = query
        , store = storeTxWalletsHistory
        }
