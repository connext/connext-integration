// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IDSA} from "./interfaces/IDSA.sol";
import {InstaTargetAuthInterface} from "./interfaces/InstaTargetAuthInterface.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract InstaTargetAuth is EIP712, InstaTargetAuthInterface {
    // Instadapp contract on this domain
    bytes32 public constant CASTDATA_TYPEHASH =
        keccak256(
            "CastData(string[] _targetNames,bytes[] _datas,address _origin)"
        );

    constructor() EIP712("InstaTargetAuth", "1") {}

    function verify(
        address auth,
        bytes memory signature,
        CastData memory castData
    ) public view returns (bool) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    CASTDATA_TYPEHASH,
                    castData._targetNames,
                    castData._datas,
                    castData._origin
                )
            )
        );
        address signer = ECDSA.recover(digest, signature);
        return signer == auth;
    }

    function authCast(
        address dsaAddress,
        address auth,
        bytes memory signature,
        CastData memory castData
    ) public payable {
        IDSA dsa = IDSA(dsaAddress);
        require(dsa.isAuth(auth), "Invalid Auth");
        require(verify(auth, signature, castData), "Invalid signature");

        // send funds to DSA
        dsa.cast{value: msg.value}(
            castData._targetNames,
            castData._datas,
            castData._origin
        );
    }
}
