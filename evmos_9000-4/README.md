# Evmos Testnet

## Instructions

## Full nodes and general participants

Follow the instructions on the official documentation to [join the testnet](https://evmos.dev/validators/testnet.html) and how to obtain tokens using the [faucet](https://evmos.dev/developers/faucet.html).

## Genesis File

Download the genesis file [genesis.json](https://archive.evmos.dev/evmos_9000-4/genesis.json)

Verify the SHA256 checksum using:

```bash
sha256sum genesis.json
# 5c8c6e7f3c9017dc6ad6a3a72e436bde1163470dbfa294b593d0e7bc8e3e7d08  genesis.json
```

## Details

- Network Chain ID: `evmos_9000-4`
- EIP155 Chain ID: `9000`
- `evmosd` version: [`v10.0.0-rc1`](https://github.com/evmos/evmos/releases)
- Faucet: [faucet.evmos.dev](https://faucet.evmos.dev)
- EVM explorer: [evm.evmos.dev](https://evm.evmos.dev)
- Cosmos explorer: [explorer.evmos.dev](https://explorer.evmos.dev)

## Seeds & Peers

You can find seeds & peers on the seeds.txt and peers.txt files, respectively. If you want to share your seed or peer, please fork this repo and and add it to the bottom of the corresponding .txt file.
