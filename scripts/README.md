# Scripts

Mix of scripts that run in GitHub Actions and locally.

## Running locally
To run `validate-gentx-macos.sh`, install the following dependencies
```
brew install gsed coreutils moreutils boxes
```

You may need to adjust env variables. Here are the defaults
```
EVMOS_HOME="/tmp/evmosd$(date +%s)"
RANDOM_KEY="randomevmosvalidatorkey"
CHAIN_ID="evmos_9000-2"
DENOM="aphoton"
MAXBOND="1000000000000" # 1 PHOTON
DAEMON="./build/evmosd"
GH_URL="https://github.com/tharsis/evmos"
BINARY_VERSION="v0.2.0"
GENTXS_DIR="$HOME/testnets/olympus_mons/gentx-300"
TMPFILE=$(mktemp)
```