# ICRC-72 Publisher for Motoko

`icrc72-publisher-mo` is a stateful Motoko component for registering ICRC-72
publications, assigning event identifiers, batching events by broadcaster, and
handling ICRC-77 replay delivery.

The package uses the ClassPlus and migration patterns so callers can retain and
migrate publisher state across canister upgrades.

## Install

```sh
mops add icrc72-publisher-mo
```

```motoko
import Publisher "mo:icrc72-publisher-mo";
```

See [`src/example/canister.mo`](src/example/canister.mo) for construction and
environment wiring.

## Toolchain

- Motoko `1.8.2`
- Core `2.4.0`
- Champ Map `0.1.0`

The publisher exposes a narrow structural subscriber interface instead of
depending on a particular subscriber implementation. It does not implement
ICRC-85 or charge publisher actions; tokenomics are intentionally left to the
integrating system.

## Verification

```sh
mops install
dfx build --check example
mops bench --compare
```

The saved batching benchmark compares Base Buffer, Core List, and Core
PureList. Buffer is retained for dynamic publisher batches because Core List
used more instructions and garbage collection allocation, while PureList's
instruction savings caused substantially more allocation.

## Repository

Maintained by [ICDevs.org](https://icdevs.org) at
https://github.com/icdevsorg/icrc72-publisher-mo.
