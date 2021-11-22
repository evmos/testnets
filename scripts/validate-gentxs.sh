#!/bin/sh
EVMOS_HOME="/tmp/evmosd$(date +%s)"
RANDOM_KEY="randomevmosvalidatorkey"
CHAIN_ID="evmos_9000-2"
DENOM="aphoton"
MAXBOND="1000000000000" # 1 PHOTON
DAEMON="./build/evmosd"
GH_URL="https://github.com/tharsis/evmos"
BINARY_VERSION="v0.2.0"
GENTXS_DIR="$HOME/testnets/olympus_mons/gentx-300"

# NOTE: This script is designed to run locally. We need to just adjust the one for CI. Not sure if the CI machine has `sponge`
# On MacOS, I use gsed instead of sed.

# contains(string, substring)
#
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1. POSIX Compliant.
contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

set -e
echo "Cloning the Evmos repo and building $BINARY_VERSION"

rm -rf evmos
git clone $GH_URL
cd evmos
git checkout tags/$BINARY_VERSION
make build
chmod +x $DAEMON

echo "Adding random validator key so that we can start the network ourselves"
$DAEMON keys add $RANDOM_KEY --keyring-backend test --home "$EVMOS_HOME"
$DAEMON init --chain-id $CHAIN_ID validator --home "$EVMOS_HOME"

# Setting the genesis time earlier so that we can start the network in our test
gsed -i '/genesis_time/c\   \"genesis_time\" : \"2021-03-29T00:00:00Z\",' "$EVMOS_HOME"/config/genesis.json
# Update the various denoms in the genesis
jq -r --arg DENOM "$DENOM" '(..|objects|select(has("denom"))).denom |= $DENOM | .app_state.staking.params.bond_denom = $DENOM | .app_state.mint.params.mint_denom = $DENOM' "$EVMOS_HOME"/config/genesis.json | sponge "$EVMOS_HOME"/config/genesis.json
cat "$EVMOS_HOME"/config/genesis.json

echo "Making a genesis copy, as we are using it as a template for adding our gen txs"
cp "$EVMOS_HOME"/config/genesis.json "$EVMOS_HOME"/config/genesis.json.bak

# Don't allow GenTx file names with spaces
echo "Get rid of spaces"
find "$GENTXS_DIR" -type f -name "* *" | while read -r GENTX_FILE
do
    echo "whitespace on $GENTX_FILE; won't process" | tee -a bad_gentxs.out
done

# Process all the GenTx files, one at a time, so that we can detect which ones are flawed
GENTX_FILES=$(find "$GENTXS_DIR" -type f -regex "[^ ]*.json")
for GENTX_FILE in $GENTX_FILES
do
    echo "Processing gentx file::"
    echo "$GENTX_FILE"
    
    GENACC=$(jq -r '.body.messages[0].delegator_address' "$GENTX_FILE")
    denomquery=$(jq -r '.body.messages[0].value.denom' "$GENTX_FILE")
    amountquery=$(jq -r '.body.messages[0].value.amount' "$GENTX_FILE")

    echo $GENACC
    echo $amountquery
    echo $denomquery

    # only allow $DENOM tokens to be bonded
    if [ "$denomquery" != $DENOM ]; then
        echo "incorrect denomination on $GENTX_FILE" | tee -a bad_gentxs.out
        continue
    fi

    # limit the amount that can be bonded
    if [ $amountquery -gt $MAXBOND ]; then
        echo "bonded too much: $amountquery > $MAXBOND on $GENTX_FILE" | tee -a bad_gentxs.out # TODO: double check this, not sure if correct
        continue
    fi
    # TODO could add checks for commission rate but will be caught by evmosd start
    # check for duplicate accounts
    OUTPUT=$($DAEMON add-genesis-account "$GENACC" 1000000000000000$DENOM --home "$EVMOS_HOME" 2>&1 || true)
    if contains "$OUTPUT" "Error"; then
        echo "add-genesis-account failed on $GENTX_FILE" | tee -a bad_gentxs.out
        continue
    fi 

    $DAEMON add-genesis-account $RANDOM_KEY 100000000000000$DENOM --home "$EVMOS_HOME" \
        --keyring-backend test

    $DAEMON gentx $RANDOM_KEY 90000000000000$DENOM --home "$EVMOS_HOME" \
        --keyring-backend test --chain-id $CHAIN_ID

    cp "$GENTX_FILE" "$EVMOS_HOME"/config/gentx/

    echo "Collecting gentxs"
    OUTPUT=$($DAEMON collect-gentxs --home "$EVMOS_HOME" 2>&1 || true)
    if contains "$OUTPUT" "Error"; then
        echo "collect-gentxs failed on $GENTX_FILE" | tee -a bad_gentxs.out
        # remove gentxs and reset genesis
        rm -rf "$EVMOS_HOME"/config/gentx/*.json
        rm -rf "$EVMOS_HOME"/config/genesis.json
        cp "$EVMOS_HOME"/config/genesis.json.bak "$EVMOS_HOME"/config/genesis.json
        continue
    fi
    gsed -i '/persistent_peers =/c\persistent_peers = ""' "$EVMOS_HOME"/config/config.toml # TODO: Should be sed, but gsed for local mac testing

    echo "Run validate-genesis on created genesis file"
    if ! $DAEMON validate-genesis --home "$EVMOS_HOME"; then 
        echo "validate-genesis failed on $GENTX_FILE" | tee -a bad_gentxs.out
        # remove gentxs and reset genesis
        rm -rf "$EVMOS_HOME"/config/gentx/*.json
        rm -rf "$EVMOS_HOME"/config/genesis.json
        cp "$EVMOS_HOME"/config/genesis.json.bak "$EVMOS_HOME"/config/genesis.json
        continue
    fi

    echo "Starting the node to get complete validation (module params, signatures, etc.)"
    TMPFILE=$(mktemp)
    $DAEMON start --home "$EVMOS_HOME" > "$TMPFILE" 2>&1 &

    # TODO: RUN COMMAND IN BACKGROUND BUT IF THERE'S A PANIC WE CAN SEND IT TO THE FILE

    sleep 3 # TODO: change to 5s when pushing

    echo "Checking the status of the network"
    OUTPUT=$($DAEMON status --node http://localhost:26657 2>&1 || true)
    if contains "$OUTPUT" "Error"; then
        PANIC=$(grep "panic" "$TMPFILE")
        echo "status check (faulty params or signatures, $PANIC) failed on $GENTX_FILE" | tee -a bad_gentxs.out
    else 
        echo $OUTPUT
        echo "Killing the daemon"
        killall evmosd >/dev/null 2>&1
    fi

    echo "Remove gentx files to process next ones"
    rm -rf "$EVMOS_HOME"/config/gentx/*.json

    echo "Reset the genesis file and the chain"
    rm -rf "$EVMOS_HOME"/config/genesis.json
    cp "$EVMOS_HOME"/config/genesis.json.bak "$EVMOS_HOME"/config/genesis.json
    $DAEMON unsafe-reset-all

done

echo "Cleaning the files"
rm -rf "$EVMOS_HOME" >/dev/null 2>&1
