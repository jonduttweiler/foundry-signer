# foundry-signer

A learning project that implements **EIP-712 typed data signing** from scratch in Solidity and tests it with [Foundry](https://book.getfoundry.sh/).

The goal is to understand, step by step, how an off-chain signature becomes an on-chain authorization, without relying on a library that hides the details.

> **Educational code. Not audited. Do not use in production.**

## What it does

`PermitToken` is an ERC-20 token (built on OpenZeppelin) with a hand-written `permit` function in the spirit of [ERC-2612](https://eips.ethereum.org/EIPS/eip-2612):

1. The token holder signs a typed message off-chain (no gas needed).
2. Anyone submits that signature to `permit(owner, spender, value, deadline, v, r, s)`.
3. The contract rebuilds the EIP-712 digest, recovers the signer with `ecrecover`, and checks that it matches `owner`.
4. The signature is bound to a single use through a per-owner nonce, and to a single token and chain through the EIP-712 domain separator.

### Differences from ERC-2612

This implementation is intentionally simplified, so it is **not** a drop-in ERC-2612 token:

- `permit` performs a `_transfer` from `owner` to `spender` instead of setting an allowance with `_approve`.
- It uses `ecrecover` directly, with no protection against malleable signatures (`s` in the upper half of the curve).
- It requires `deadline > block.timestamp` where the standard uses `>=`.

## How the signature is built

| Piece | Where |
|---|---|
| Domain separator: `keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(name), keccak256(version), chainId, address(this)))` | [src/PermitToken.sol](src/PermitToken.sol) constructor |
| Struct hash: `keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonce, deadline))` | `verifySignature` |
| Digest: `keccak256("\x19\x01" ‖ domainSeparator ‖ structHash)` | `verifySignature` |
| Signer recovery with `ecrecover` | `verifySignature` |

The nonce is read from contract storage rather than passed in, so a replayed signature produces a different digest and recovers a different address.

## Tests

The tests in [test/PermitToken.t.sol](test/PermitToken.t.sol) build the digest independently, sign it with the `vm.sign` cheatcode, and check:

- a valid signature moves the tokens,
- a signature from a different account is rejected,
- a signature whose `value` was altered is rejected.

An expired-signature test is still a stub.

## Getting started

Requirements: [Foundry](https://book.getfoundry.sh/getting-started/installation).

```shell
git clone --recurse-submodules <repo-url>
cd foundry-signer
forge build
forge test -vv
```

If you cloned without `--recurse-submodules`, run `git submodule update --init --recursive`.

## Deploying to Celo Sepolia

| | |
|---|---|
| Chain ID | `11142220` |
| RPC | `https://forno.celo-sepolia.celo-testnet.org` |
| Explorer | `https://celo-sepolia.blockscout.com` |
| Faucet | `https://faucet.celo.org/celo-sepolia` |

Create a testnet-only account in Foundry's encrypted keystore, fund it from the faucet, then run a deploy script:

```shell
cast wallet new ~/.foundry/keystores deployer
forge script script/<YourScript>.s.sol --rpc-url $CELO_SEPOLIA_RPC --account deployer              # simulate
forge script script/<YourScript>.s.sol --rpc-url $CELO_SEPOLIA_RPC --account deployer --broadcast  # send
```

Never use a key that holds real funds for testing.

## Project layout

```
src/     PermitToken.sol        the contract
test/    PermitToken.t.sol      signature tests using vm.sign
script/  deployment scripts
lib/     forge-std, openzeppelin-contracts (git submodules)
```

## References

- [EIP-712: Typed structured data hashing and signing](https://eips.ethereum.org/EIPS/eip-712)
- [ERC-2612: Permit extension for ERC-20](https://eips.ethereum.org/EIPS/eip-2612)
- [Foundry Book](https://book.getfoundry.sh/)

## License

MIT
