#!/bin/sh
EVMOS_HOME="/tmp/evmosd$(date +%s)"
RANDOM_KEY="randomevmosvalidatorkey"
# CHAIN_ID=evmos_9000-2
# DENOM=aphoton
MAXBOND=50000000000000 # 500 Million PHOTON

# GENTX_FILE=$(find ./$CHAIN_ID/gentxs -iname "*.json")
GENTX_FILE=$(find $GENTXS_DIR -iname "*.json")
LEN_GENTX=$(echo ${#GENTX_FILE})

# Gentx Start date
start="2021-11-17 22:00:00Z"
# Compute the seconds since epoch for start date
stTime=$(date --date="$start" +%s)

# Gentx End date
end="2021-11-19 20:00:00Z"
# Compute the seconds since epoch for end date
endTime=$(date --date="$end" +%s)

# Current date
current=$(date +%Y-%m-%d\ %H:%M:%S)
# Compute the seconds since epoch for current date
curTime=$(date --date="$current" +%s)

if [[ $curTime < $stTime ]]; then
    echo "start=$stTime:curent=$curTime:endTime=$endTime"
    echo "Gentx submission is not open yet. Please close the PR and raise a new PR after 04-June-2021 23:59:59"
    exit 0
else
    if [[ $curTime > $endTime ]]; then
        echo "start=$stTime:curent=$curTime:endTime=$endTime"
        echo "Gentx submission is closed"
        exit 0
    else
        echo "Gentx is now open"
        echo "start=$stTime:curent=$curTime:endTime=$endTime"
    fi
fi

if [ $LEN_GENTX -eq 0 ]; then
    echo "No new gentx file found."
else
    set -e

    echo "GentxFile::::"
    echo $GENTX_FILE

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
    curl -s $PRELAUNCH_GENESIS_URL > $EVMOS_HOME/config/genesis.json

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

    # echo "..........Starting node......."
    # ./build/evmosd start --home $EVMOS_HOME &

    # sleep 180s

    # echo "...checking network status.."

    # ./build/evmosd status --node http://localhost:26657

    echo "...Cleaning the stuff..."
    # killall evmosd >/dev/null 2>&1
    rm -rf $EVMOS_HOME >/dev/null 2>&1
fi
