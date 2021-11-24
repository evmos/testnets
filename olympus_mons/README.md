# Olympus Mons Testnet

![cover](/img/olympus_mons.png)

## Instructions

**Genesis Validators**

Follow the instructions on the ["Running as a genesis validator"](https://github.com/tharsis/testnets/blob/main/olympus_mons/run.md) guide.

**Full nodes and general particpants**

Follow the instructions on the official documentation to [join the testnet](https://evmos.dev/testnet/join.html) and how to obtain tokens using the [faucet](https://evmos.dev/testnet/faucet.html).

## Genesis File

Download the minified genesis file [genesis.json](./genesis.json)

Verify the SHA256 checksum using:

```bash
sha256sum genesis.json
# 2b5164f4bab00263cb424c3d0aa5c47a707184c6ff288322acc4c7e0c5f6f36f  genesis.json
```

## Details

- Network Chain ID: `evmos_9000-2`
- EIP155 Chain ID: `9000`
- `evmosd` version: [`v0.3.x`](https://github.com/tharsis/evmos/releases)
- Faucet: [faucet.evmos.org](https://faucet.evmos.org)
- EVM explorer: [evm.evmos.org](https://evm.evmos.org)
- Cosmos explorer: [explorer.evmos.org](https://explorer.evmos.org)

## Schedule

### Application Period

Submissions open on November 17, 2021 14:00 PST, participants are required to [submit gentx](./gentx.md).

Submissions close on November 18, 2021 17:00 PST.

### Genesis Launch

November 25, 2021 19:00 UTC.
