# Evmos Incentivized Testnet Gentx

A `gentx` does three things:

- Registers the validator account you created as a validator operator account (i.e. the account that controls the validator).
- Self-delegates the provided amount of staking tokens.
- Links the operator account with a Tendermint node pubkey that will be used for signing blocks. If no `--pubkey` flag is provided, it defaults to the local node pubkey created via the `evmosd init` command.

Software:

- Go version: [v1.17+](https://golang.org/dl/)
- Evmos version: [v0.2.x](https://github.com/tharsis/evmos/releases)

## genesis params (changed from default)

```json
"max_validators": 300
"send_enabled": false
"receive_enabled": false
"signed_blocks_window": "10000"
"min_signed_per_window": "0.050000000000000000"
"unbonding_time": "86400s"
"voting_period": "86400s"
```

- You have to keep up at least 5% in the last 10000block for avoid downtime slashing.
- You have to wait 3days to unbond your token.

## GenTx Collection (Until October 16, 2021 11:59 UTC End)

1. Install `evmosd`

   ```bash
   git clone https://github.com/tharsis/evmos
   cd evmos && git checkout -b XXX tags/XXXXX
   make install
   ```

   Make sure to checkout to `XXXXX` tag.

2. Initialize the `evmosd` directories and create the local file with the correct chain-id

   ```bash
   evmosd init <moniker> --chain-id=evmos_9000-2
   ```

3. Create a local key pair in the keybase

   ```bash
   evmosd keys add <your key name>
   ```

   Make sure to keep mnemonic seed which will be used to receive rewards at the time of mainnet launch.

4. Add the account to your local genesis file with a given amount and key you just created.

   ```bash
   evmosd add-genesis-account $(evmosd keys show <your key name> -a) 1000000000000aphoton
   ```

   Make sure to use `aphoton` denom, not `photon`.

5. Create the gentx

   ```bash
   evmosd gentx <your key name> 1000000000000aphoton --commission-rate=0.1 --commission-max-rate=1 --commission-max-change-rate=0.1 --pubkey $(evmosd tendermint show-validator) --chain-id=evmos_9000-2
   ```

6. Create Pull Request to this repository ([evmos/gentxs](./gentxs)) with the file `<your validator moniker>.json`.
