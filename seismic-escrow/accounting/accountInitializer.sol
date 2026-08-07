// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;
import './user.sol';
import '../lib/error.sol';
contract accountInitializer{
    address public immutable RiftHub = address(0); // update required for RiftHub address

    modifier onlyRiftHub(){
        if(msg.sender != RiftHub){
            bytes4 selector = OnlyHub.selector;
            assembly{
                mstore(0,shl(224,selector))
                revert(0,4)
            }
        }
        _;
    }


    function createAccount(string memory _username) public onlyRiftHub returns(address account){
        bytes memory bytecode = type(user).creationCode;
        bytes memory arg = abi.encode(_username);
        bytes4 selector = InitializingFailed.selector;
        assembly{
            let argSize := mload(arg)
            let bytecodeSize := mload(bytecode)
            let ptr := mload(0x40)
            //final byte code
            mcopy(ptr,add(bytecode,32),bytecodeSize) //storing contract bytecode
            //written bits = ptr + bytecode size
            mcopy(add(ptr,bytecodeSize),add(arg,32),argSize)
            account := create2(0,ptr,add(argSize,bytecodeSize),caller())
            if eq(account,0) {
                mstore(0, shl(224, selector))
                revert(0,4)
            }
            mstore(0x40,add(ptr,add(argSize,bytecodeSize)))
            
        }
    }

}