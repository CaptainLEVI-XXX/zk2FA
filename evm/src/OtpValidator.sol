// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IOtpMerkleTreeVerifier} from './interfaces/IOtpMerkleTreeVerifier.sol';

contract OtpValidator {
    //keccak256("root.zk2fa")
    bytes32 constant ROOT_SLOT = 0xeb7c90e68c37a7418b15ab0d1c43e9078100dc7d2a4f5aaeef0abf6614540d58;

    //keccak256("verifier.zk2fa")
    bytes32 constant VERIFIER_SLOT = 0x9bed8c9b2ac8f3b1e9cceef5833d74cbc5c54d034095518cf82f791538f55a58;

    //keccak256("lastValidatedTimestamp.zk2fa")
    bytes32 constant LAST_VALIDATED_TIMESTAMP_SLOT = 0xcdafa7c254dab7f97d1db2c4b33c476e498637077495fcd50523acffd7982442;

    constructor(uint256 _root, address _verifier) {
        assembly {
            sstore(ROOT_SLOT, _root)
            sstore(VERIFIER_SLOT, _verifier)
        }
    }

    function getRoot() public view returns (uint256 root) {
        assembly {
            root := sload(ROOT_SLOT)
        }
    }

    function getVerifier() public view returns (address verifier) {
        assembly {
            verifier := sload(VERIFIER_SLOT)
        }
    }

    function getLastValidatedTimeStamp() public view returns (uint256 _time) {
        assembly {
            _time := sload(LAST_VALIDATED_TIMESTAMP_SLOT)
        }
    }

    function verifyOTP(uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c, uint256[2] memory input)
        public
        returns (bool success)
    {
        uint256 time = input[1];
        require(input[0] == getRoot(), "Incorrect root");
        require(time > getLastValidatedTimeStamp(), "Old Proof");
        require(IOtpMerkleTreeVerifier(getVerifier()).verifyProof(a, b, c, input), "Invalid proof");

        assembly {
            sstore(LAST_VALIDATED_TIMESTAMP_SLOT, time)
        }
        success = true;
    }
}
