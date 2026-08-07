// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import '../lib/DataTypes.sol';
import '../lib/error.sol';
import './bargain.sol';

contract bargainDeployer{
    address private RiftHub ;
    
    modifier onlyHub() {
    bytes4 selector = OnlyHub.selector;
        if(msg.sender != RiftHub){
            assembly{
                mstore(0, shl(224, selector))
                revert(0,4)
        }
        }
        _;
    }


    function newRealBargain(
        EscrowParams memory params,bytes32 salt
    ) external  onlyHub returns(address bargainAdrs) {

        bytes memory bytecode = type(bargain).creationCode;
        bytes memory args = abi.encode(params,salt);
        
        // Designed as an ultra-low-gas indexing key for the Rift DApp frontend.
        // Packed (20-byte Seller + 12-byte Truncated Buyer) into a single EVM word.
        // Reduces keccak256 cost by eliminating unnecessary memory expansion gas.
        // Absolute source of truth remains verifiable via on-chain emitted events.


        bytes4 selector = BargainCreationFailed.selector;
        assembly {
            let ptr := mload(0x40)
            let argSize := mload(args)
            let bytecodeSize := mload(bytecode)
            mcopy(ptr,add(bytecode,32),bytecodeSize)
            mcopy(add(ptr,bytecodeSize),add(args,32),argSize)
            bargainAdrs := create2(0,ptr,add(argSize,bytecodeSize),salt)
            mstore(0x40,add(ptr,add(argSize,bytecodeSize)))
            if eq(bargainAdrs,0x0000000000000000000000000000000000000000){
                mstore(0, shl(224, selector))
                revert(0, 4)
            }
        }
    }

}