# Evmos Testnet

## Instructions

## Full nodes and general participants

Follow the instructions on the official documentation to [join the testnet](https://evmos.dev/testnet/join.html) and how to obtain tokens using the [faucet](https://evmos.dev/testnet/faucet.html).

## Genesis File

Download the zipped genesis file [genesis.zip](./genesis.zip)

Extract it with command

```bash
unzip genesis.zip
```

Verify the SHA256 checksum using:

```bash
sha256sum genesis.json
# f00df30e2dce9467ab3b6952f28e22a9f3be6f1e51dca2953e21e77befef87a5  genesis.json
```

## Details

- Network Chain ID: `evmos_9000-3`
- EIP155 Chain ID: `9000`
- `evmosd` version: [`v1.0.0-beta1`](https://github.com/tharsis/evmos/releases)
- Faucet: [faucet.evmos.org](https://faucet.evmos.org)
- EVM explorer: [evm.evmos.org](https://blockscout.evmos.org)
- Cosmos explorer: [explorer.evmos.org](https://explorer.evmos.org)

## Seeds & Peers

You can find seeds & peers on the seeds.txt and peers.txt files, respectively. If you want to share your seed or peer, please fork this repo and and add it to the bottom of the corresponding .txt file.
