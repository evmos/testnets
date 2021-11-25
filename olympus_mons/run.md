# Running as a genesis validator

## GenTx submissions are done and closed!

To see if you were included in the final genesis, search the `genesis.json` file or the `final-gentxs` folder for your `moniker`, `delegator_address` or other identifiers unique to you.

If you were included, congrats! there were a lot of submissions to process and we're glad to have you.

If you weren't, thank you for taking the time to submit - we suggest looking at the [Mars Meteor Missions](https://evmos.blog/evmos-incentivized-testnet-event-the-mars-meteor-missions-bbbb7ffa1b7c) for participating in the Olympus Mons incentivzed testnet as the rewards can end up much higher for the other missions!

We encourage you to find ways to jail validators if you're really interested in becoming part of the 300 once the network launches, subject to our [Code of Conduct](https://www.notion.so/tharsis/Code-of-Conduct-for-Evmos-Incentivized-Testnet-802fc5298ef647ca954c5dc0d44d39c1).

## For selected validators
**The Chain Genesis Time is 19:00 UTC on Nov 25, 2021.**

Please have your validator up and ready by this time, and be available for further instructions if necessary
at that time.

The primary point of communication for the genesis process will be the #validator-chat
channel on the [Evmos Discord](https://discord.gg/PJeeUYRHuY). It is absolutely critical that you
and your team join the Discord during launch, as it will be the coordination point in case of any hiccups
or issues during the launch process.

## Instructions

This guide assumes that you have completed the tasks involved in [Submitting your GenTx for the Evmos Incentivized Testnet](./gentx.md).  You should
be running on a machine that meets the [hardware requirements specified in the Evmos Docs](https://evmos.dev/guides/validators/setup.html#minimum-requirements)
with Go installed.  We are assuming you already have a daemon home ($HOME/.evmosd)
setup.

These instructions are for creating a basic setup on a single node. Validators should modify these instructions
for their own custom setups as needed (i.e. sentry nodes, tmkms, etc).

These examples are written targeting an Ubuntu 20.04 system.  Relevant changes to commands should be made depending on the OS/architecture you are running on.

### Update `evmosd` to `v0.3.0`

For the gentx creation, we used the `v0.2.0` release of the [Evmos codebase](https://github.com/tharsis/evmos).

For launch, please update to the `v0.3.0` tag and rebuild your binaries.

```sh
git clone https://github.com/tharsis/evmos
cd evmos
git checkout tags/v0.3.0

make install
```

### Verify Your Installation

Verify that everything is OK. If you get something *like* the following, you've successfully installed Evmos on your system.

```sh
evmosd version --long

name: evmos
server_name: evmosd
version: 0.3.0
commit: 070b668f2cbbf52548c46e96b236e09884483dd4
build_tags: netgo,ledger
go: go version go1.17 darwin/amd64
```
If the software version does not match, then please check your `$PATH` to ensure the correct `evmosd` is running.

### Save your Chain ID in evmosd config

If you haven't done so already, please save the mainnet chain-id to your client.toml. This will make it so you do not have to manually pass in the chain-id flag for every CLI command.

```sh
evmosd config chain-id evmos_9000-2
```

### Install and setup Cosmovisor

We highly recommend validators use cosmovisor to run their nodes. This will make low-downtime upgrades more smoother,
as validators don't have to manually upgrade binaries during the upgrade, and instead can preinstall new binaries, and
cosmovisor will automatically update them based on on-chain Software Upgrade proposals.

You should review the docs for cosmovisor located here: https://docs.cosmos.network/master/run-node/cosmovisor.html

If you choose to use cosmovisor, please continue with these instructions:

Cosmovisor is currently located in the Cosmos SDK repo, so you will need to download that, build cosmovisor, and add it
to you PATH.

```sh
git clone https://github.com/cosmos/cosmos-sdk
cd cosmos-sdk
git checkout v0.44.3
make cosmovisor
cp cosmovisor/cosmovisor $GOPATH/bin/cosmovisor
cd $HOME
```

After this, you must make the necessary folders for cosmosvisor in your daemon home directory (~/.evmosd).

```sh
mkdir -p ~/.evmosd
mkdir -p ~/.evmosd/cosmovisor
mkdir -p ~/.evmosd/cosmovisor/genesis
mkdir -p ~/.evmosd/cosmovisor/genesis/bin
mkdir -p ~/.evmosd/cosmovisor/upgrades
```

Cosmovisor requires some ENVIRONMENT VARIABLES be set in order to function properly.  We recommend setting these in
your `.profile` so it is automatically set in every session.

```
echo "# Setup Cosmovisor" >> ~/.profile
echo "export DAEMON_NAME=evmosd" >> ~/.profile
echo "export DAEMON_HOME=$HOME/.evmosd" >> ~/.profile
echo 'export PATH="$DAEMON_HOME/cosmovisor/current/bin:$PATH"' >> ~/.profile
source ~/.profile
```

Finally, you should move the evmosd binary into the cosmovisor/genesis folder.
```
mv $GOPATH/bin/evmosd ~/.evmosd/cosmovisor/genesis/bin
```

### Download Genesis File

You can now download the "genesis" file for the chain.  It is pre-filled with the entire genesis state and gentxs.

```sh
curl https://raw.githubusercontent.com/tharsis/testnets/main/olympus_mons/genesis.json > ~/.evmosd/config/genesis.json
```

We recommend using `sha256sum` to check the hash of the genesis.
```sh
sha256sum 2b5164f4bab00263cb424c3d0aa5c47a707184c6ff288322acc4c7e0c5f6f36f ~/.evmosd/config/genesis.json
```

### Reset Chain Database

There shouldn't be any chain database yet, but in case there is for some reason, you should reset it. This is a good idea especially if you ran `evmosd start` on an old, broken genesis file.

```sh
evmosd unsafe-reset-all
```

### Start your node

Now that everything is setup and ready to go, you can start your node.

```sh
cosmovisor start
```

You will need some way to keep the process always running.  If you're on linux, you can do this by creating a 
service.

```sh
sudo tee /etc/systemd/system/evmosd.service > /dev/null <<EOF  
[Unit]
Description=Evmos Daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) start
Restart=always
RestartSec=3
LimitNOFILE=infinity

Environment="DAEMON_HOME=$HOME/.evmosd"
Environment="DAEMON_NAME=evmosd"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"

[Install]
WantedBy=multi-user.target
EOF
```


Then update and start the node

```sh
sudo -S systemctl daemon-reload
sudo -S systemctl enable evmosd
sudo -S systemctl start evmosd
```

You can check the status with:
```sh
systemctl status evmosd
```

### Configure Your Firewall (Recommended)

This will contribute to the overall health of the network and better secure your node instance.

Disable firewall

`ufw disable`

Set defaults for incoming/outgoing ports

```sh
ufw default deny incoming
ufw default allow outgoing

Re-enable the firewall

`ufw enable`  
`ufw status verbose`

Allow inbound peers to connect

```
sudo ufw allow from any to any port 26656 proto tcp
```

_In production you would configure these firewall settings on your sentries only. See the [validator security section](https://evmos.dev/guides/validators/security.html) in the Evmos docs for information on making a secure validator set up with sentries._

## Conclusion

See you all at launch!  Join the discord!

---
*Disclaimer: This content is provided for informational purposes only, and should not be relied upon as legal, business, investment, or tax advice. You should consult your own advisors as to those matters. References to any securities or digital assets are for illustrative purposes only and do not constitute an investment recommendation or offer to provide investment advisory services. Furthermore, this content is not directed at nor intended for use by any investors or prospective investors, and may not under any circumstances be relied upon when making investment decisions.*

*This work, ["Running as a genesis validator"](https://github.com/tharsis/testnets/blob/main/olympus_mons/run.md) is a derivative of ["Osmosis Genesis Validators Guide"](https://github.com/osmosis-labs/networks/genesis-validators.md), used under [CC BY](http://creativecommons.org/licenses/by/4.0/). The "Osmosis Genesis Validators Guide" itself is a derivative of ["Agoric Validator Guide"](https://github.com/Agoric/agoric-sdk/wiki/Validator-Guide), used under [CC BY](http://creativecommons.org/licenses/by/4.0/). The Agoric validator guide is itself is a derivative of ["Validating Kava Mainnet"](https://medium.com/kava-labs/validating-kava-mainnet-72fa1b6ea579) by [Kevin Davis](https://medium.com/@kevin_35106), used under [CC BY](http://creativecommons.org/licenses/by/4.0/). "Running as a genesis validator" is licensed under [CC BY](http://creativecommons.org/licenses/by/4.0/) by [Tharsis Labs](https://tharsis.notion.site/). It was extensively modified to be relevant to the Evmos chain.*
