// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;
import './accounting/user.sol';
import './real-world-bargain/bargain.sol';
import './real-world-bargain/interface/IJudge.sol';


contract RiftHub{
    address public immutable globalFee;
    address public immutable bargainDeployer;
    mapping(address => bool) public hasSettled;
    mapping (address => address) public accounts;

    function initializeAccount(address _user,string memory _username) public returns(bool){

        {if(_user != msg.sender || accounts[_user] != address(0)) return false;}
        address _account = pf.account(_username,address(0)); // update required for account deployer address
        accounts[_user] = _account;
        hasSettled[msg.sender] = true;
        return true;

    }

    mapping(bytes32 => address) public bargains;
    //one sloted (buyer,seller,dealNumber)
    mapping (bytes32 => dealer) public dealers;
    //one sloted (buyer,seller)
    function newRealBargain(
        EscrowParams memory params
    ) public returns(address bargainContract) {
        address buyer = params.buyer;
        address seller = params.seller;
        //codes for error handling of valid judge incentive number between 0-100
        bytes32 dealerSlot;
        assembly{
            let truncatedBuyer := shr(64,buyer)
            let shiftedSeller := shl(96,seller)
            dealerSlot := or(truncatedBuyer,shiftedSeller)
        }
        (dealers[dealerSlot].buyer , dealers[dealerSlot].seller) = (buyer,seller);
        dealers[dealerSlot].dealNumber++;
        uint256 dealNum = dealers[dealerSlot].dealNumber;
        bytes32 salt;
        assembly{
            let ptr := mload(0x40)
            mstore(ptr,buyer)
            mstore(add(ptr,32),seller)
            mstore(add(ptr,64),dealNum)
            salt := keccak256(ptr,96)
        }
        
        
        // Designed as an ultra-low-gas indexing key for the Rift DApp frontend.
        // Packed (20-byte Seller + 12-byte Truncated Buyer) into a single EVM word.
        // Reduces keccak256 cost by eliminating unnecessary memory expansion gas.
        // Absolute source of truth remains verifiable via on-chain emitted events.

        address bargainAdrs = pf.newBargain(bargainDeployer, params, salt);
        bargains[salt] = bargainAdrs;
        bargainContract = bargainAdrs;

    }

    mapping(bytes32 => judgeTimes) public allJudges;
    //keccak(buyer,seller)
    mapping(bytes32 => judgeDetail) public judgeDetails;
    //keccak(buyer,seller,judgeNumber)


    modifier onlyValidBargain(){
        bytes4 selector = InvalidCallerOnlyRiftAddressesAllowed.selector;
        bytes32 slot = pf.getBargainSlot(msg.sender);
        uint256 mappingSlot;assembly{mappingSlot := bargains.slot}
        pf.isValidBargain(slot,mappingSlot, selector);
        _;
    }
    function startJudgementUpdate() external onlyValidBargain returns(uint256 judgeNum){

        if(pf.getDealStatus() == dealingProgress.JudgeRequested){
            bytes32 judgeSlot = pf.getJudgeSlot(msg.sender);
            allJudges[judgeSlot].judgeNumber++;
            uint256 judgeNumber = allJudges[judgeSlot].judgeNumber;
            return judgeNumber;
        }
        
    }

    function endJudgementUpdate(address buyer , address seller) external onlyValidBargain returns(bool updated){
        address judgeContract = pf.getJudgeContract(msg.sender);
        if(pf.judgeHasEnded(judgeContract)){
            bool mustUpdateDetails = pf.mustUpdate(judgeContract);
            uint256 judgeNum = allJudges[pf.getJudgeSlot(msg.sender)].judgeNumber;
            if(mustUpdateDetails){
                bytes32 Slot = pf.getJudgeDetailsSlot(buyer, seller,judgeNum);
                uint8 winner = pf.getJudgeWinner(judgeContract);
                judgeDetails[Slot] = judgeDetail({
                    bargainKey:pf.getBargainKey(msg.sender),
                    judge:judgeContract,
                    winner:winner
                });
                
                // if(winner == 1 || winner == 2){
                //     judgeManager memory globalFeeDetails = judgeManager({
                //         bargain:msg.sender,
                //         incentive:pf.getIncentive(msg.sender),
                //         token:pf.getCurrency(msg.sender),
                //         winner:winner == 1 ? true:false
                //     });
                //     if(!pf.setGlobalFee(globalFee,Slot,globalFeeDetails)){
                //         bytes4 selector = SetGlobalFeeFailed.selector;
                //         assembly{
                //             mstore(0,shl(224,selector))
                //             revert(0,4)
                //         }
                //     }
                //     }
                }
                
                return true;
            }
            return false;
            
                // ending for judge canceling
        
        
        }

    

    //-----------update profile--------------

    //codes function for staking


    //codes for changing wallet address of an account contains deleting the key : value of previous address 


    //codes for updating total votes + successful votes

    function settlementCheck(address _voter) external returns(bool settleRequired){
        if(judgeDetails[pf.getSlotForSettlement(msg.sender)].judge == msg.sender){
            hasSettled[_voter] = false;
            return true;

        }
    }
    function settle(bytes32 judgement) public returns(bool updated){

        uint256 amount;
        uint8 Vote; //0 no vote , 1 good vote , 2 bad vote
        {
        address _judge = judgeDetails[judgement].judge;
        uint256 conditionAndAmount = IJudge(_judge).amountForVoter(msg.sender);
        uint8 condition = uint8(conditionAndAmount << 254);
        assembly{
            switch condition
            case 3{
                amount := shr(2,shl(2,conditionAndAmount))
                Vote := 1
            }
            case 2{
                amount := 0
                Vote := 2
            }
            default {
                amount := 0
                Vote := 0
            }
        }
        }
        if(amount > 0){
            //codes for updating profile settlement amount and successful votes
            address _token = pf.getCurrency(bargains[judgeDetails[judgement].bargainKey]);
            pf.updateUserVotesAndSettlement(msg.sender,1,amount,_token);
            updated = true;

        } else if(amount == 0 && Vote == 2){
            //codes for updating profile  total votes
            pf.updateUserVotesAndSettlement(msg.sender,-1,0,address(0));
            updated = true;
        } else{
            bytes4 selector = NoSettlementForThisJudge.selector;
            assembly{
                mstore(0,shl(224,selector))
                revert(0,4)
            }
        }



    }
}
