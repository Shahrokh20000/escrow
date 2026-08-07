// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import './interface/IRift.sol';
import './interface/IBargain.sol';
import '../lib/error.sol';


contract judge{
    address public immutable RiftHub;
    uint256 public immutable defaultDeadline ;
    uint256 private immutable period;
    address public immutable seller;
    address public immutable buyer;
    uint256 public immutable dealNumber;
    address public immutable bargainContract;
    uint256 public immutable amount;
    uint256 public immutable judgeNumberBetweenTheseDealers;
    uint120 private buyerVotes;
    uint120 private sellerVotes;
    uint16 public renewed = 0;
    mapping(address => uint8) public hasVoted; //0 for has not voted , 1 for buyer , 2 for seller
    bytes32 public constant deadlineSlot = keccak256("global.newDeadline.slot if votes are equal and deadline has ended");
    uint8 public judgeWinner = 0; // 0 for no result yet , 1 for buyer , 2 for seller, 3 judge canceled by buyer , 4 judge canceled by seller
    bool public hasEnded;
    bool public isUpdatedInRiftHub;
    uint256 public votesMultiplier;

    



    constructor(judgeFrame memory params,address bargain){
        defaultDeadline = params.defaultDeadline;
        period = defaultDeadline - block.timestamp;
        bargainContract = bargain;
        seller = params.seller;
        buyer = params.buyer;
        judgeNumberBetweenTheseDealers = params.judgeNumberBetweenTheseDealers;
        amount = params.amount;
        dealNumber = params.dealNumber;
        RiftHub = params.RiftHub;
    }

    function vote(
        bool _myVote //true for buyer , false for seller
    ) public returns (bool voted) {
        //deadline reverting error
        if(renewed == 1){
            bytes32 slot = deadlineSlot;
            uint256 deadline;
            bytes4 selector = DeadlineEnded.selector;
            assembly{
                deadline := sload(slot)
                if iszero(gt(deadline,timestamp())){
                    mstore(0,shl(224,selector))
                    revert(0,4)
                }
            }
        }else{
            if(defaultDeadline < block.timestamp) revert DeadlineEnded();
        }
        if(hasVoted[msg.sender] != 0) revert VoterHasAlreadyVoted();
        if ( IRift(RiftHub).hasSettled(msg.sender) && IBargain(bargainContract).filterVoters(msg.sender)) {
            if (_myVote) {
                buyerVotes++;
        }   else {
            sellerVotes++;
        }
            voted =  true;
    }   else {
            voted =  false;
    }
}


    function winner() public view returns(uint8 val){ // 1 for buyer 2 for seller 3 equal 4 for deadline not ended
        if(renewed == 1){
            uint256 deadline;
            bytes32 slot = deadlineSlot;
            assembly{
                deadline := sload(slot)
            }
            if(block.timestamp < deadline) return uint8(4);
        }else{
            if(block.timestamp < defaultDeadline) return uint8(4);
        }
        if(buyerVotes > sellerVotes) return uint8(1);
        if(buyerVotes == sellerVotes) return uint8(3);
        else return uint8(2);
    }

    function renewDeadline() public returns(bool success){
        if((msg.sender == buyer || msg.sender == seller) && block.timestamp > defaultDeadline && winner() == 3){
            bytes32 slot = deadlineSlot;
            uint256 prd = period;
            assembly{
                let newDeadline := add(prd,timestamp())
                sstore(slot,newDeadline)
            }
            if(renewed == 0) renewed = 1;
            return true;
        }
    }
    function endJudgement() external returns(bool ended){ //1 for buyer ,2 for seller 
        uint8 result = winner();
        if(result == 1){
            judgeWinner = 1;
            votesMultiplier = amount / buyerVotes;
            hasEnded = true;
        }else if(result == 2){
            judgeWinner = 2;
            votesMultiplier = amount / sellerVotes;
            hasEnded=true;
        }

        if(votesMultiplier != 0){
            //codes to control remaining balance
            return true;
        }
        return false;

    }
    function updateDetailsInRiftHub() external returns(bool){
        if(hasEnded && msg.sender == RiftHub && !isUpdatedInRiftHub){
            isUpdatedInRiftHub = true;
            return true;
        }
        return false;
        
    }

    function emergencyJudgeEnding(uint8 _detail) external returns(bool ended){
        if(!hasEnded && msg.sender == bargainContract){
            hasEnded = true;
            judgeWinner = _detail;
            votesMultiplier = 0;
            delete buyerVotes;
            delete sellerVotes;
            delete renewed;
            ended = true;
        }
    }

    function amountForVoter(address _voter) external view returns(uint256 _amount){
        uint8 Vote = hasVoted[_voter];
        _amount = votesMultiplier;
        uint8 _winner = judgeWinner;
        if(hasEnded){
            assembly{
                let mergeNum

                switch eq(Vote,_winner)
                case 1{
                    mergeNum := 3
                }
                case 0{
                    switch gt(Vote,0)
                    case 0{
                        mergeNum := 0
                    }
                    case 1{
                        mergeNum := 2
                    }
                }

                mergeNum := shl(254,mergeNum)
                if shr(254,_amount){
                    let mask := shr(2,not(0))
                    _amount := and(_amount,mask)
                }
                _amount := or(_amount,mergeNum)
            }


            return _amount;
        }
        return 0;

    }
}