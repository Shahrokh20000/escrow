// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import './judge.sol';
import '../lib/DataTypes.sol';

contract judgeDeployer{
    address public immutable RiftHub;
    constructor(address _riftHub){
        RiftHub = _riftHub;
    }
    modifier onlyRiftBargains(){
        //codes to check bargain address
        _;
    }



    function createJudge(judgeFrame memory params,address bargainContract) external onlyRiftBargains() returns(address _judge){
            bytes memory arg = abi.encode(params,bargainContract);
            bytes memory bytecode = type(judge).creationCode;
            address _buyer = params.buyer;
            address _seller = params.seller;
            uint256 num = params.judgeNumberBetweenTheseDealers;
            assembly{
                mstore(0,_buyer)
                mstore(32,_seller)
                mstore(64,num)
                let salt := keccak256(0,96)
                let argSize := mload(arg)
                let bytecodeSize := mload(bytecode)
                let ptr := mload(0x40)
                mcopy(ptr,add(bytecode,32),bytecodeSize)
                mcopy(add(ptr,bytecodeSize),add(arg,32),argSize)
                _judge := create2(0,ptr,add(bytecodeSize,argSize),salt)
            }
    }
}