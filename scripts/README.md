# Scripts

Mix of scripts that run in GitHub Actions and locally.

## Running locally

**validate-gentx-macos.sh**

You can use this script to validate a bunch of gentxs in a folder, one by one
and get an output file containing the errors that occurred on which files.
Useful if you're working with a directory of potentially broken gentx files.

To run `validate-gentx-macos.sh`, install the following dependencies

```bash
brew install gsed coreutils moreutils boxes
```

And run it from the parent directory, `testnets`

```bash
chmod +x scripts/validate-gentx-macos.sh
./scripts/validate-gentx-macos.sh
```

You may need to adjust env variables. Here are the defaults

```bash
EVMOS_HOME="/tmp/evmosd$(date +%s)"
RANDOM_KEY="randomevmosvalidatorkey"
CHAIN_ID="evmos_9000-2"
DENOM="aphoton"
MAXBOND="1000000000000" # 0.000001 PHOTON
GENACC_BALANCE="1000000000000000000" # 1 PHOTON
DAEMON="./build/evmosd"
GH_URL="https://github.com/tharsis/evmos"
BINARY_VERSION="v0.3.0"
GENTXS_DIR="$HOME/testnets/olympus_mons/gentxs"
TMPFILE=$(mktemp)
OUTFILE="$HOME/testnets/bad-gentxs.txt"
```

Check the `$OUTFILE` to see which gentx files are broken.
