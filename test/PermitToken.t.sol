// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {PermitToken} from "../src/PermitToken.sol";

contract PermitTokenTest is Test {
    PermitToken public token;

    function setUp() public {
        token = new PermitToken("TestToken", "TT", "1", 1000e18);
    }

    function faucet(address target, uint256 value) public {
        token.transfer(target, value);
    }

    function build_digest(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline
    ) public view returns (bytes32 digest) {
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        uint256 nonce = token.nonces(owner);

        bytes32 structHash = keccak256(
            abi.encode(token.TYPEHASH(), owner, spender, value, nonce, deadline)
        );

        digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        return digest;
    }

    function build_invalid_digest(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline
    ) public view returns (bytes32 digest) {
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        uint256 nonce = token.nonces(owner) + 1;

        bytes32 structHash = keccak256(
            abi.encode(token.TYPEHASH(), owner, spender, value, nonce, deadline)
        );

        digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        return digest;
    }

    function test_transfer() public {
        (address alice, uint256 aliceKey) = makeAddrAndKey("alice");
        address bob = makeAddr("bob");
        uint256 deadline = block.timestamp + 10 minutes;
        bytes32 digest = build_digest(alice, bob, 1e18, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);

        faucet(alice, 1e18);
        assertEq(token.balanceOf(bob), 0);

        token.permit(alice, bob, 1e18, deadline, v, r, s);

        assertEq(token.balanceOf(bob), 1e18);
        assertEq(token.balanceOf(alice), 0);
    }

    function test_invalidSigner() public {
        address alice = makeAddr("alice");
        (address bob, uint256 bobKey) = makeAddrAndKey("bob");
        uint256 deadline = block.timestamp + 10 minutes;
        bytes32 digest = build_digest(alice, bob, 1e18, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(bobKey, digest);

        faucet(alice, 1e18);
        vm.expectRevert("Invalid signer: signature does not match owner");
        token.permit(alice, bob, 1e18, deadline, v, r, s);
    }
    function test_invalidValue() public {
        (address alice, uint256 aliceKey) = makeAddrAndKey("alice");
        address bob = makeAddr("bob");
        uint256 deadline = block.timestamp + 10 minutes;
        bytes32 digest = build_digest(alice, bob, 1e18, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);

        faucet(alice, 5e18);
        vm.expectRevert("Invalid signer: signature does not match owner");
        token.permit(alice, bob, 2e18, deadline, v, r, s);
    }
    function test_expiredSignature() public {
        (address alice, uint256 aliceKey) = makeAddrAndKey("alice");
        address bob = makeAddr("bob");
        uint256 deadline = block.timestamp + 10 minutes;
        bytes32 digest = build_digest(alice, bob, 1e18, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);

        faucet(alice, 5e18);
        vm.warp(deadline + 1 seconds);

        vm.expectRevert("Signature has expired");
        token.permit(alice, bob, 1e18, deadline, v, r, s);
    }

    function test_insufficientFunds() public {
        (address alice, uint256 aliceKey) = makeAddrAndKey("alice");
        address bob = makeAddr("bob");
        uint256 deadline = block.timestamp + 10 minutes;
        bytes32 digest = build_digest(alice, bob, 2e18, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);

        faucet(alice, 1e18);

        vm.expectRevert("Insufficient funds");
        token.permit(alice, bob, 2e18, deadline, v, r, s);
    }

    function test_invalidNonce() public {
        (address alice, uint256 aliceKey) = makeAddrAndKey("alice");
        address bob = makeAddr("bob");
        uint256 deadline = block.timestamp + 10 minutes;
        bytes32 digest = build_invalid_digest(alice, bob, 2e18, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);

        faucet(alice, 1e18);

        vm.expectRevert("Invalid signer: signature does not match owner");
        token.permit(alice, bob, 2e18, deadline, v, r, s);
    }
}
