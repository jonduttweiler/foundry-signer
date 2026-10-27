// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//Podemos hacer que esto funcione con USDC? creo que no

contract PermitToken is ERC20 {
    string version;
    address verifyingContract;
    bytes32 public DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    bytes32 constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public constant TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    function orDefault(address a, address fallback_) internal pure returns (address) {
        return a != address(0) ? a : fallback_;
    }

    constructor(string memory name, string memory symbol, string memory version_, uint256 initialSupply)
        ERC20(name, symbol)
    {
        _mint(msg.sender, initialSupply);

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version_)),
                block.chainid,
                address(this)
            )
        );
    }

    function verifySignature(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address) {
        bytes32 structHash = keccak256(abi.encode(TYPEHASH, owner, spender, value, nonces[owner], deadline));

        bytes32 message = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));

        address signer = ecrecover(message, v, r, s);

        require(signer != address(0), "Invalid signature");

        return signer;
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        address signer = verifySignature(owner, spender, value, deadline, v, r, s);
        require(owner == signer, "Invalid signer: signature does not match owner");
        require(deadline > block.timestamp, "Signature has expired");
        require(balanceOf(owner) >= value, "Insufficient funds");

        //esto tiene un error enorme, puedo pasar una firma valida pero que el value no coincida con el mensaje que se firmo
        //no estoy tan seguro, pero vale la pena pegarle una mirada, digo que no porque cuando calcule la firma el value no puede ser distinto
        _transfer(owner, spender, value);
        nonces[owner]++;
    }
}
