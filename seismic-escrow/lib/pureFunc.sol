// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import '../real-world-bargain/interface/IBargain.sol';
import '../real-world-bargain/interface/IJudge.sol';
import '../real-world-bargain/interface/IRift.sol';
import '../real-world-bargain/interface/IJudgeDeployer.sol';
import '../real-world-bargain/interface/IGlobalFee.sol';
import './DataTypes.sol';
import '../accounting/interface/IInitializer.sol';
import '../accounting/interface/IUser.sol';
import '../real-world-bargain/interface/IBargainDeployer.sol';


    function getBargainSlot(address Contract) view returns(bytes32){
        address buyer = IBargain(Contract).buyer();
        address seller = IBargain(Contract).seller();
        uint256 dealNum = IBargain(Contract).dealNumber();
        bytes32 slot;
        assembly{
            let ptr := mload(0x40)
            mstore(ptr,buyer)
            mstore(add(ptr,32),seller)
            mstore(add(ptr,64),dealNum)
            slot := keccak256(ptr,96)
        }
        return slot;
    }
    function getJudgeContract(address Contract) view returns(address){
        return IBargain(Contract).getJudgeAdrs();
    }
    function isValidBargain(bytes32 _key ,uint256 mappingSlot, bytes4 _selector) view {
            assembly{
            let ptr := mload(0x40)
            mstore(ptr,_key)
            mstore(add(ptr,32),mappingSlot)
            let slot := keccak256(ptr,64)
            if iszero(eq(sload(slot),caller())){
                mstore(ptr,shl(224,_selector))
                revert(ptr,4)
            }
        }
    }
    function judgeHasEnded(address Contract) view returns(bool){
        return IJudge(Contract).hasEnded();
    }
    function getJudgeWinner(address Contract) view returns(uint8){
        return(IJudge(Contract).judgeWinner());
    }

    function getJudgeSlot(address Contract) view returns(bytes32 judgeSlot){
        address buyer = IBargain(Contract).buyer();
        address seller = IBargain(Contract).seller();
        assembly{
            let truncatedBuyer := shr(64,buyer)
            let shiftedSeller := shl(96,seller)
            judgeSlot := or(truncatedBuyer,shiftedSeller)
        }
    }
    function mustUpdate(address Contract) returns(bool){
        return IJudge(Contract).updateDetailsInRiftHub();
    }

    function getJudgeNum(address Contract) returns(uint256){
        return IRift(Contract).startJudgementUpdate();
    }


    function getJudgeDetailsSlot(address _buyer , address _seller , uint256 _judgeNum) pure returns(bytes32 judgeDetailsSlot){
        assembly{
            let ptr := mload(0x40)
            mstore(ptr,_buyer)
            mstore(add(ptr,32),_seller)
            mstore(add(ptr,64),_judgeNum)
            judgeDetailsSlot := keccak256(ptr,96)
        }
    }
    function getDealStatus() view returns(dealingProgress){
        return IBargain(msg.sender).dealStatus();

    }
    function judgeCreation(judgeFrame memory params,address _bargain,address _deployerAdrs) returns(address){
        return IJudgeDeployer(_deployerAdrs).createJudge(params,_bargain);
    }

    function account(string memory _username,address _deployer) returns (address _account){
        return IInitializer(_deployer).createAccount(_username);
    }
    function getAccount(address _rift,address _voter) view returns(address _account){
        return IRift(_rift).accounts(_voter);
    }
    function getProfile(address _account) view returns(profileStruct memory _profile){
        return IUser(_account).profile();
    }
    function getRegisterTime(address _account) view returns(uint _time){
        return IUser(_account).registrationTime();
    }
    function cancelJudge(address _judgeAdrs,uint8 _detail) returns(bool ended){
        return IJudge(_judgeAdrs).emergencyJudgeEnding(_detail);
    }
    function setGlobalFee(address globFee ,bytes32 _slot , judgeManager memory _datails) returns(bool updated){
        return IGlobalFee(globFee).updateJudges( _slot,_datails);
    }
    function getIncentive(address _bargain) view returns(uint256){
        return IBargain(_bargain).judgeIncentive();
    }
    function getCurrency(address _bargain) view returns(address){
        return IBargain(_bargain).currency();
    }
    function lockJudgeContract(address _judge) returns(bool){
        return IJudge(_judge).endJudgement();
    }
    function getBargainKey(address bargainContract) view returns(bytes32){
        return IBargain(bargainContract).BARGAIN_KEY();
    }
    function getSlotForSettlement(address judgeContract) returns(bytes32){
        (address _buyer,address _seller,uint256 judgeNum) = (IJudge(judgeContract).buyer(),IJudge(judgeContract).seller(),IJudge(judgeContract).judgeNumberBetweenTheseDealers());
        return getJudgeDetailsSlot( _buyer ,  _seller ,judgeNum);
    }
    function updateUserVotesAndSettlement(address _user, int32 _vote, uint256 amount , address _token) returns(bool updated){
        profileStruct memory _profile;
        if(_vote > 0){
            _profile.totalVotes = 1;
            _profile.successfulVotes = 1;
            return IUser(_user).updateProfile(_profile,_token,int256(amount),true);
        }
        if(_vote < 0){
            _profile.totalVotes = 1;
            return IUser(_user).updateProfile(_profile,address(0),0,false);
        }
    }

    function newBargain(address _deployer,EscrowParams memory params,bytes32 salt) returns(address){
        return IBargainDeployer(_deployer).newRealBargain(params,salt);
    }