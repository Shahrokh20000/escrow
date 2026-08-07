// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import '../lib/error.sol';
import '../lib/DataTypes.sol';

contract user {

    profileStruct public profile;
    address public immutable RiftHub;
    uint256 public immutable registrationTime = block.timestamp;
    address[] public creditors; //list of tokens settled in judgements
    mapping(address => creditorStructure) public settlement; // amount of tokens as creditor

    constructor(string memory _username){
        profile.username  = _username;
        RiftHub = msg.sender;
    }

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

    function updateProfile(
    profileStruct memory _profile ,
    address _creditorToken, //address zero for native balance
    int256 _creditorTokenAmount,
    bool updateSettle
    )
    external onlyHub returns(bool updated){
        profileStruct memory __profile;
        if(_profile.wallet != address(0)) __profile.wallet = _profile.wallet;
        if (_profile.stakedBalance > 0) __profile.stakedBalance += _profile.stakedBalance;
        else if (_profile.stakedBalance < 0) __profile.stakedBalance -= _profile.stakedBalance;
        if (_profile.totalVotes > 0) __profile.totalVotes += _profile.totalVotes;
        profile = __profile;
        if (updateSettle) {
            if(!settlement[_creditorToken].addedToCreditors){
                settlement[_creditorToken].addedToCreditors = true;
                creditors.push(_creditorToken);
            }
            _creditorTokenAmount > 0
            ?settlement[_creditorToken].tokenMultiplier += int240(_creditorTokenAmount)
            :settlement[_creditorToken].tokenMultiplier -= int240(_creditorTokenAmount);
                
    }
    updated = true;
    }
    

    

}