# Evmos Mainnet Dry Run

## Instructions

## Full nodes and general participants

Follow the instructions on the official documentation to [carry out a manual upgrade](https://docs.evmos.org/validators/upgrades/manual.html) with a [data reset](https://docs.evmos.org/validators/upgrades/manual.html#_3-data-reset).

## Genesis File

Download the zipped genesis file [dryrun_genesis.json.zip](./dryrun_genesis.json.zip)

Extract it with command

```bash
unzip dryrun_genesis.json.zip
mv dryrun_genesis.json genesis.json
```

Verify the SHA256 checksum using:

```bash
sha256sum genesis.json
# 87e0e45b4f5278556af7cf31e6d856aa418dc883ffc7c80066a78b356c309dc6  genesis.json
```

## Step-by-Step

These are abbreviated version of the instructions linked above.

1. Move the genesis file into your config

```
cp -f genesis.json $HOME/.evmosd/config
```

2. **BACK UP ALL PRIVATE KEYS, YOU WILL NEED THESE FOR MAINNET**

3. Remove any previous state

```
rm $HOME/.evmosd/config/addrbook.json
evmosd tendermint unsafe-reset-all --home=$HOME/.evmosd
```

4. Start the chain

```
evmosd start
```

## Details

- Network Chain ID: `evmosdryrun_9009-1`
- EIP155 Chain ID: `9009`
- `evmosd` version: [`v3.0.0`](https://github.com/tharsis/evmos/releases)

## Schedule

Genesis: `2022-04-26T19:00:00Z`

Airdrop: `2022-04-26T22:00:00Z`

## Seeds & Peers

You can find seeds & peers on the seeds.txt and peers.txt files, respectively. If you want to share your seed or peer, please fork this repo and and add it to the bottom of the corresponding .txt file.
