#!/bin/sh
EVMOS_HOME="/tmp/evmosd$(date +%s)"
RANDOM_KEY="randomevmosvalidatorkey"
MAXBOND="1000000000000" # 0.000001 PHOTON
GENACC_BALANCE="1000000000000000000" # 1 PHOTON

# NOTE: This script is designed to run in CI.

print() {
    echo "$1" | boxes -d stone
}

set -e
print "Cloning the Evmos repo and building $BINARY_VERSION"

rm -rf evmos
git clone "$GH_URL" > /dev/null 2>&1
cd evmos
git checkout tags/"$BINARY_VERSION" > /dev/null 2>&1
make build > /dev/null 2>&1
chmod +x "$DAEMON"

# Get the diff between main and commit
GENTX_FILE=$(git -C "$PROJECT_DIR" diff --name-only main HEAD -- "$GENTX_DIR")
LEN_GENTX=${#GENTX_FILE}

if [ $LEN_GENTX -eq 0 ]; then
    print "No new gentx file found."
else
    # TODO: Check if white space in name
    GENACC=$(jq -r '.body.messages[0].delegator_address' "$GENTX_FILE")
    denomquery=$(jq -r '.body.messages[0].value.denom' "$GENTX_FILE")
    amountquery=$(jq -r '.body.messages[0].value.amount' "$GENTX_FILE")

    # only allow $DENOM tokens to be bonded
    if [ "$denomquery" != $DENOM ]; then
        echo "incorrect denomination on $GENTX_FILE" | tee -a bad_gentxs.out
        exit 1
    fi

    # limit the amount that can be bonded
    if [ $amountquery -gt $MAXBOND ]; then
        echo "bonded too much: $amountquery > $MAXBOND on $GENTX_FILE" | tee -a bad_gentxs.out
        exit 1
    fi
    
    # Adding random validator key so that we can start the network ourselves
    $DAEMON keys add $RANDOM_KEY --keyring-backend test --home "$EVMOS_HOME" > /dev/null 2>&1
    $DAEMON init --chain-id $CHAIN_ID validator --home "$EVMOS_HOME" > /dev/null 2>&1
    
    # Setting the genesis time earlier so that we can start the network in our test
    sed -i '/genesis_time/c\   \"genesis_time\" : \"2021-03-29T00:00:00Z\",' "$EVMOS_HOME"/config/genesis.json
    # Update the various denoms in the genesis
    jq -r --arg DENOM "$DENOM" '(..|objects|select(has("denom"))).denom |= $DENOM | .app_state.staking.params.bond_denom = $DENOM | .app_state.mint.params.mint_denom = $DENOM' "$EVMOS_HOME"/config/genesis.json | sponge "$EVMOS_HOME"/config/genesis.json
    
    # Add genesis accounts
    $DAEMON add-genesis-account "$GENACC" $GENACC_BALANCE$DENOM --home "$EVMOS_HOME"
    $DAEMON add-genesis-account $RANDOM_KEY $GENACC_BALANCE$DENOM --home "$EVMOS_HOME" \
        --keyring-backend test

    $DAEMON gentx $RANDOM_KEY $MAXBOND$DENOM --home "$EVMOS_HOME" \
        --keyring-backend test --chain-id $CHAIN_ID

    cp "$GENTX_FILE" "$EVMOS_HOME"/config/gentx/
    $DAEMON collect-gentxs --home "$EVMOS_HOME"

    sed -i '/persistent_peers =/c\persistent_peers = ""' "$EVMOS_HOME"/config/config.toml
    print "Run validate-genesis on created genesis file"
    $DAEMON validate-genesis --home "$EVMOS_HOME"

    print "Starting the node to get complete validation (module params, signatures, etc.)"
    $DAEMON start --home "$EVMOS_HOME" &

    sleep 3s

    print "Checking the status of the network"
    $DAEMON status --node http://localhost:26657 

    print "Killing the daemon"
    killall evmosd > /dev/null 2>&1

    print "Cleaning the files"
    rm -rf "$EVMOS_HOME" >/dev/null 2>&1
fi

print "Done."
