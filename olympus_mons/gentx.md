# Submitting your GenTx for the Evmos Incentivized Testnet

Thank you for becoming a genesis validator on Evmos! This guide will provide instructions on setting up a node, submitting a gentx, and other tasks needed to participate in the launch of the Evmos Olympus Mons incentivized testnet.

A `gentx` does three things:

- Registers the validator account you created as a validator operator account (i.e. the account that controls the validator).
- Self-delegates the provided amount of staking tokens.
- Links the operator account with a Tendermint node pubkey that will be used for signing blocks. If no `--pubkey` flag is provided, it defaults to the local node pubkey created via the `evmosd init` command.

## Setup

Software:

- Go version: [v1.17+](https://golang.org/dl/)
- Evmos version: [v0.3.x](https://github.com/tharsis/evmos/releases)

To verify that Go is installed:

```sh
go version
# Should return go version go1.17 linux/amd64
```

## Instructions (Until November 19, 2021 12AM PST)

These instructions are written targeting an Ubuntu 20.04 system.  Relevant changes to commands should be made depending on the OS/architecture you are running on.

1. Install `evmosd`

   ```bash
   git clone https://github.com/tharsis/evmos
   cd evmos && git checkout tags/v0.3.x
   make install
   ```

   Make sure to checkout to some `v0.3.x` tag.

   Verify that everything is OK. If you get something *like* the following, you've successfully installed Evmos on your system.

   ```sh
   evmosd version --long

   name: evmos
   server_name: evmosd
   version: '"0.3.0"'
   commit: 7ad7715c59ec38fd19c06de54d03a982afebf961
   build_tags: netgo,ledger
   go: go version go1.17 darwin/amd64
   ```

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
   evmosd gentx <your key name> 1000000000000aphoton \
     --chain-id=evmos_9000-2 \
     --moniker=<moniker> \
     --details="My moniker description" \
     --commission-rate=0.05 \
     --commission-max-rate=0.2 \
     --commission-max-change-rate=0.01 \
     --pubkey $(evmosd tendermint show-validator) \
     --identity="<Keybase.io GPG Public Key>"
   ```

6. Create Pull Request to the repository ([tharsis/testnets]()) with the file  `olympus_mons/gentxs/<your validator moniker>.json`. In order to be a valid submission, you need the .json file extension and no whitespace or special characters in your filename. Your PR should be one addition.