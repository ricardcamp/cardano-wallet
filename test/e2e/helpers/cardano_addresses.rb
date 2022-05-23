##
# cardano-address cmd helper wrapper
#
class CardanoAddresses
  ##
  # @param mnemonics
  # @param type = Byron | Icarus | Shelley | Shared
  def prv_key_from_recovery_phrase(mnemonics, type)
    cmd(%(echo #{mnemonics.join(' ')}| cardano-address key from-recovery-phrase #{type})).gsub("\n", '')
  end

  def key_public(key, with_chain_code = true)
    cmd(%(echo #{key}| cardano-address key public #{with_chain_code ? "--with-chain-code" : "--without-chain-code"})).gsub("\n", '')
  end

  def key_child(key, derivation_path)
    cmd(%(echo #{key}| cardano-address key child #{derivation_path})).gsub("\n", '')
  end

  def key_walletid(key, templates = '')
    cmd(%(echo #{key}| cardano-address key walletid #{templates})).gsub("\n", '')
  end
end
