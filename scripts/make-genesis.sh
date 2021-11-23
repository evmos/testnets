#!/bin/sh
EVMOS_HOME="/tmp/evmosd$(date +%s)"
CHAIN_ID="evmos_9000-2"
DENOM="aphoton"
MAXBOND="1000000000000" # 0.000001 PHOTON
DAEMON="./build/evmosd"
GH_URL="https://github.com/tharsis/evmos"
BINARY_VERSION="v0.2.0"
GENTXS_DIR="$HOME/testnets/olympus_mons/valid-gentxs"
FAUCET1="evmos1ht560g3pp729z86s2q6gy5ws6ugnut8r4uhyth"
FAUCET2="evmos1hefvrgzc85hmn2nwdk3lhttk6jwlzzgv6e8tmc"
FAUCET_BALANCE="250000000000000000000000" # 250,000 PHOTON
GENESIS_START_TIME="2021-11-20T17:00:00.000000Z" # in UTC
GENESIS_OUTPUT="$HOME/testnets/olympus_mons/valid_genesis.json"

# NOTE: This file assumes you've ran through gentx validation. It is also meant
# for local usage right now and tested on MacOS.

print() {
    echo "$1" | boxes -d stone
}

set -e
print "Cloning the Evmos repo and building $BINARY_VERSION"

rm -rf evmos
git clone $GH_URL > /dev/null 2>&1
cd evmos
git checkout tags/$BINARY_VERSION > /dev/null 2>&1
make build > /dev/null 2>&1
chmod +x $DAEMON

print "Creating genesis file"
$DAEMON init --chain-id $CHAIN_ID validator --home "$EVMOS_HOME" > /dev/null 2>&1

# Update the various denoms, genesis time, and other params
jq -r --arg denom "$DENOM" --arg genesis_start_time "$GENESIS_START_TIME" '
    (..|objects|select(has("denom"))).denom |= $denom |
    .app_state.staking.params.bond_denom = $denom |
    .app_state.mint.params.mint_denom = $denom |
    .genesis_time = $genesis_start_time |
    .app_state.intrarelayer.params.token_pair_voting_period = "86400s" |
    .app_state.staking.params.unbonding_time = "259200s" |
    .app_state.staking.params.max_validators = ("300" | tonumber) |
    .app_state.feemarket.params.no_base_fee = false |
    .app_state.feemarket.params.enable_height = "0" |
    .app_state.crisis.constant_fee.amount = "5000000000000000000" |
    .consensus_params.block.time_iota_ms = "30000"' \
    "$EVMOS_HOME"/config/genesis.json | sponge "$EVMOS_HOME"/config/genesis.json

# TODO: Add renaming substitutions and jq merges

print "Adding genesis accounts to genesis file"
GENTX_FILES=$(find "$GENTXS_DIR" -type f -regex "[^ ]*.json")
for GENTX_FILE in $GENTX_FILES
do
    GENACC=$(jq -r '.body.messages[0].delegator_address' "$GENTX_FILE")
    $DAEMON add-genesis-account "$GENACC" $MAXBOND$DENOM --home "$EVMOS_HOME"
done

# Faucet accounts
$DAEMON add-genesis-account "$FAUCET1" $FAUCET_BALANCE$DENOM --home "$EVMOS_HOME"
$DAEMON add-genesis-account "$FAUCET2" $FAUCET_BALANCE$DENOM --home "$EVMOS_HOME"

mkdir -p "$EVMOS_HOME"/config/gentx/
cp "$GENTXS_DIR/"*.json "$EVMOS_HOME"/config/gentx/
print "Collecting gentxs into genesis file"
$DAEMON collect-gentxs --home "$EVMOS_HOME"


print "Run validate-genesis on created genesis file"
$DAEMON validate-genesis --home "$EVMOS_HOME" 
cp "$EVMOS_HOME"/config/genesis.json "$GENESIS_OUTPUT"

print "Cleaning the files"
rm -rf "$EVMOS_HOME" >/dev/null 2>&1

echo "Done."