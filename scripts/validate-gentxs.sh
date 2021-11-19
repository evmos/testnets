#!/bin/sh
EVMOS_HOME="/tmp/evmosd$(date +%s)"
RANDOM_KEY="randomevmosvalidatorkey"
# CHAIN_ID=evmos_9000-2
# DENOM=aphoton
MAXBOND=50000000000000 # 500 Million PHOTON

set -e
echo "...........Init Evmos.............."

git clone $GH_URL
cd evmos
git checkout tags/v0.2.0
make build
chmod +x ./build/evmosd

./build/evmosd keys add $RANDOM_KEY --keyring-backend test --home $EVMOS_HOME

./build/evmosd init --chain-id $CHAIN_ID validator --home $EVMOS_HOME

echo "..........Fetching genesis......."
rm -rf $EVMOS_HOME/config/genesis.json
curl -s $PRELAUNCH_GENESIS_URL > $EVMOS_HOME/config/genesis.json.bak

# Loop through the GenTx Files
GENTX_FILES=$(find $GENTXS_DIR -iname "*.json")
for GENTX_FILE in $GENTX_FILES
do
    echo "GentxFile::::"
    echo $GENTX_FILE

    echo "..........Reset genesis......."
    rm -rf $EVMOS_HOME/config/genesis.json
    cp $EVMOS_HOME/config/genesis.json.bak $EVMOS_HOME/config/genesis.json

    # this genesis time is different from original genesis time, just for validating gentx.
    # sed -i '/genesis_time/c\   \"genesis_time\" : \"2021-03-29T00:00:00Z\",' $EVMOS_HOME/config/genesis.json

    GENACC=$(cat $GENTX_FILE | sed -n 's|.*"delegator_address":"\([^"]*\)".*|\1|p')
    denomquery=$(jq -r '.body.messages[0].value.denom' $GENTX_FILE)
    amountquery=$(jq -r '.body.messages[0].value.amount' $GENTX_FILE)

    echo $GENACC
    echo $amountquery
    echo $denomquery

    # only allow $DENOM tokens to be bonded
    if [ $denomquery != $DENOM ]; then
        echo "invalid denomination"
        exit 1
    fi

    # limit the amount that can be bonded
    if [ $amountquery -gt $MAXBOND ]; then
        echo "bonded too much: $amountquery > $MAXBOND"
        exit 1
    fi

    ./build/evmosd add-genesis-account $GENACC 1000000000000000$DENOM --home $EVMOS_HOME

    ./build/evmosd add-genesis-account $RANDOM_KEY 100000000000000$DENOM --home $EVMOS_HOME \
        --keyring-backend test

    ./build/evmosd gentx $RANDOM_KEY 90000000000000$DENOM --home $EVMOS_HOME \
        --keyring-backend test --chain-id $CHAIN_ID

    cp $GENTX_FILE $EVMOS_HOME/config/gentx/

    echo "..........Collecting gentxs......."
    ./build/evmosd collect-gentxs --home $EVMOS_HOME
    sed -i '/persistent_peers =/c\persistent_peers = ""' $EVMOS_HOME/config/config.toml

    ./build/evmosd validate-genesis --home $EVMOS_HOME

    
    echo "..........Clean gentxs......."
    rm -rf $EVMOS_HOME/config/gentx/*.json

    # echo "..........Starting node......."
    # ./build/evmosd start --home $EVMOS_HOME &

    # sleep 180s

    # echo "...checking network status.."

    # ./build/evmosd status --node http://localhost:26657
done

echo "...Cleaning the stuff..."
# killall evmosd >/dev/null 2>&1
rm -rf $EVMOS_HOME >/dev/null 2>&1
