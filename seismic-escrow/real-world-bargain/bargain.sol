// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;
import '../lib/safeFunctions.sol' as sf;
import '../lib/DataTypes.sol';
import '../lib/pureFunc.sol' as pf;
import '../lib/error.sol';
import './interface/IRift.sol';



    
contract bargain {


    //----------dealers------------
    bytes32 public immutable BARGAIN_KEY; 
    uint256 public immutable dealNumber;
    address public immutable RiftToken;
    address public immutable globalFeeManager;
    address public immutable buyer;
    address public immutable seller;
    uint256 public immutable bargainDeadline;
    uint256 public immutable votingDeadline;
    address public immutable RiftHub;
    address public constant judgeDeployer = address(0);// update required for judge deployer address
    agreement public agreementStatus;
    bool public dealInProgress = false;
    dealingProgress public dealStatus;
    dealSatisfaction public buyerSatisfaction;
    dealSatisfaction public sellerSatisfaction;



    //------custom voters-------
    string public ifpsHash;
    bytes32 public merkleRoot;

    //---advanced voting filter---
    address public immutable customFilterInterface;
    

    //----------voters default filter----------

    address public immutable currency;
    uint256 public immutable amount;
    uint256 public immutable deadline;
    uint256 public immutable voterBalance;
    uint256 public immutable voterStakedBalance;
    uint256 public immutable voterNativeBalance;
    uint256 public immutable minAge;
    uint256 public immutable minSuccessJudges;
    uint256 public immutable judgeIncentive;
    //error handling for percentage must be between 1-100
    // BPS format: 100 = 1%, 1000 = 10%, 10000 = 100%

    //--------------filtering way------------------
    //----controling interference on main.sol------
    bool public immutable advanced;
    bool public immutable customAddress;


    uint256 public immutable fee;
    uint256 public immutable amountLessFee;

    

    

    
   constructor(EscrowParams memory params,bytes32 key,uint256 _dealNumber) {
        buyer = params.buyer;
        seller = params.seller;
        bargainDeadline = params.bargainDeadline;
        votingDeadline = params.votingDeadline;
        currency = params.currency;  //leave zero  address if native used
        amount = params.amount;
        deadline = params.deadline;
        voterBalance = params.voterBalance; //leave zero if unused
        voterStakedBalance = params.voterStakedBalance; //leave zero if unused
        voterNativeBalance = params.voterNativeBalance; //leave zero if unused
        minAge = params.minAge; //leave zero if unused
        minSuccessJudges = params.minSuccessJudges; //leave zero if unused
        judgeIncentive = params.judgeIncentive; //leave zero if unused
        globalFeeManager = params.globalFeeManager; //unchangable
        advanced = params.advanced; //false if unused
        customAddress = params.customAddress; //false if unused
        BARGAIN_KEY = key;
        dealNumber = _dealNumber;
        customFilterInterface = params.customFilterInterface;

        

        {
            if (params.customAddress) {
                ifpsHash = params.ifpsHash;
                merkleRoot = params.merkleRoot;
            }
            if (params.advanced) {
                customFilterInterface = params.customFilterInterface;
            }

            //leave zero if being a third party service for a bargain
            if(params.dealStarter == buyer){agreementStatus.buyerConfirmed = true;} 
            else if(params.dealStarter == seller){agreementStatus.sellerConfirmed = true;}

        }

        fee = (amount * 3)/10000;
        amountLessFee = amount - fee;
    }

    //---------------modifiers--------------
    modifier onlyDealParties() {
        address _buyer = buyer;
        address _seller = seller;
        bytes4 selector = InvalidCaller.selector;
        assembly{
        if and(iszero(eq(caller(),_buyer)),iszero(eq(caller(),_seller))){
            mstore(0, shl(224, selector))
            revert(0,4)
        }
    }
    _;
    }

    modifier onlyWhileDealing(){
        bytes4 selector = DealNotInProgress.selector;
        if(!dealInProgress){
            assembly{
                mstore(0, shl(224, selector))
                revert(0,4)
            }
        }
        
        _;
    }

    modifier onlyRift(){
        bytes4 selector = OnlyHub.selector;
        if(msg.sender != RiftHub){
            assembly{
                mstore(0,shl(224,selector))
                revert(0,4)
            }
        }

        _;
    }



    //------get confirmtion-----


    function getConfirmation(bool dealerConfirmation) public onlyDealParties {
        agreement memory _agreementStatus = agreementStatus; // gas opt
        if(!_agreementStatus.buyerConfirmed && msg.sender==buyer && dealerConfirmation) _agreementStatus.buyerConfirmed = dealerConfirmation;
        else if(!_agreementStatus.sellerConfirmed && msg.sender==seller && dealerConfirmation) _agreementStatus.sellerConfirmed = dealerConfirmation;
        agreementStatus = _agreementStatus;
    }
    

    //------bargain start------


    function isConfirmed() public view returns (bool) {
        return (agreementStatus.buyerConfirmed && agreementStatus.sellerConfirmed);
    }

    function startBargain() public returns(bool started){
        if(isConfirmed() && !dealInProgress){
            agreementStatus.dealStartTime = uint240(block.timestamp);
            //check if balance has arrived
            uint256 balance = currency == address(0)
            ?sf.selfETHBalance()
            :sf.safeBalanceOf(currency,address(this));
            if(balance < amount){
                bytes4 selector = BalanceNotArrived.selector;
                assembly{
                    mstore(0, shl(224, selector))
                    revert(0,4)
                }
            }
            currency == address(0)
            ?sf.safeTransferETH(globalFeeManager,fee)
            :sf.safeTransfer(currency, globalFeeManager, fee);
            dealInProgress = true;
            started = true;
            
        }
        else{
            started = false;
        }
    }

    //------bargain ends------
    bytes32 constant public buyerAgreement = keccak256("I confirm that I have received the product and agree to release the funds.");
    bytes32 constant public sellerAgreement = keccak256("I confirm that I have sent the product and fulfilled my obligations.");
    bytes32 constant public buyerRejection = keccak256("As the buyer, I declare an unresolved dispute and acknowledge that this initiates a voting mechanism with an unpredictable outcome.");
    bytes32 constant public sellerRejection = keccak256("As the seller, I declare an unresolved dispute and acknowledge that this initiates a voting mechanism with an unpredictable outcome.");
    bytes32 constant public sellerAgreementToRefund = keccak256("As the seller, I confirm that I am unable to fulfill my obligations and authorize the immediate refund of the locked funds to the buyer.");
    bytes32 constant public buyerDisputeWithdrawal = keccak256("As the buyer, I confirm that I withdraw my dispute claim, waive the ongoing judgement process, and authorize releasing the locked funds to the seller.");
    function endBargain(bytes32 _progress) public onlyDealParties onlyWhileDealing returns(bool){
        if(msg.sender == buyer){
            if( _progress == buyerAgreement){
                dealInProgress = false;
            currency == address(0)
            ?sf.safeTransferETH(seller,amountLessFee)
            :sf.safeTransfer(currency, seller, amountLessFee);

            
                //checking contract balance on main.sol

                dealStatus = dealingProgress.WellEnded;
                buyerSatisfaction = dealSatisfaction.Satisfied;
                return true;

        }
            else if( _progress == buyerRejection){
                buyerSatisfaction = dealSatisfaction.JudgeRequest;
                dealStatus = dealingProgress.JudgeRequested;
                return false;
        }
        }
        else{           //msg.sender == seller
            if(_progress == sellerAgreement){
                sellerSatisfaction = dealSatisfaction.Satisfied;
                dealStatus = dealingProgress.OnlySellerConfirmed;
                return false;

        }
            else if( _progress == sellerRejection){
                sellerSatisfaction = dealSatisfaction.JudgeRequest;
                dealStatus = dealingProgress.JudgeRequested;
                return false;
        }
            else if( _progress == sellerAgreementToRefund){
                dealInProgress = false;
                sellerSatisfaction = dealSatisfaction.Satisfied;
                buyerSatisfaction = dealSatisfaction.Satisfied;
                
             //codes to refund the balance
                currency==address(0)
                ?sf.safeTransferETH(buyer,amountLessFee)
                :sf.safeTransfer(currency,buyer,amountLessFee);
                return true;
        }
        }

        bytes4 selector = InvalidHashInput.selector;
        assembly{
            mstore(0, shl(224, selector))
            revert(0,4)
        }

    }




    //----------voters filter---------
    function filterVoters(address _voter,uint256 _gas) external view  returns(bool){
            //no check for validating account if address has not initialized account this causes gas efficiency and tx penalty fee for fake voters
            {
            profileStruct memory _profile = pf.getProfile(pf.getAccount(RiftHub, _voter));
            if(voterStakedBalance > uint256(_profile.stakedBalance)){
                return false;
            }
            if(voterNativeBalance > _voter.balance){
                return false;
            }
            if(minAge > (pf.getRegisterTime(_profile.wallet))){
                return false;
            }
            if(minSuccessJudges > _profile.successfulVotes){
                return false;
            }
            }

            if(advanced){
                address filter = customFilterInterface;
                assembly{
                    let funcSelector := 0x66e305fd00000000000000000000000000000000000000000000000000000000
                    // selector of this function => isEligible(address)
                    // be sure the the filter interface contains this function with exact name and exact input
                    let ptr := mload(0x40)
                    let Gas := 200000
                    if iszero(eq(_gas,0)){
                        Gas := _gas
                    }
                    mstore(ptr, funcSelector)
                    mstore(add(ptr, 0x4), _voter)
                    let success := staticcall(Gas, filter, ptr, 0x24, ptr,0x20)
                    let isValidCall := and(gt(success,0),eq(returndatasize(),0x20))
                    let eligiblity := iszero(iszero(mload(ptr)))
                    if iszero(and(isValidCall,eligiblity)){
                        mstore(ptr,0)
                        return(ptr,0x20)
                    }
            }
            }

            
            return true;
            
        }

           //----------judgement status----------
    judgeStatus public winnerSide = judgeStatus.NoJudge;



//-------------------judgement----------------------//

    bytes32 constant public judgeSlot = keccak256("global.judgement.contract.slot");//gas optimized
    function storeJudgeAdrs(address Contract) private returns(uint8 stored){ //act as bool variable
        bytes32 Slot = judgeSlot;
        assembly{
            if iszero(sload(Slot)){
                sstore(Slot,Contract)
                stored := 1

            }
            if iszero(iszero(sload(Slot))){
                stored := 2
            }
        }
    }
    function getJudgeAdrs() public view returns(address adrs){
        bytes32 Slot = judgeSlot;
        assembly{
            adrs := sload(Slot)
        }
    }

    function startJudgement() public onlyDealParties onlyWhileDealing returns(bool started){
        if(dealStatus == dealingProgress.JudgeRequested){
            dealStatus = dealingProgress.WaitingForJudgement;
            uint256 num = pf.getJudgeNum(RiftHub);
            judgeFrame memory params = judgeFrame({
                RiftHub:RiftHub,
                buyer:buyer,
                seller:seller,
                defaultDeadline : deadline,
                dealNumber:dealNumber,
                bargainContract:address(this),
                amount : (amountLessFee * judgeIncentive)/10000,
                judgeNumberBetweenTheseDealers : num

            });
            address _judge = pf.judgeCreation(params,address(this),judgeDeployer);
            if(_judge != address(0)){
                winnerSide = judgeStatus.Ongoing;
                return true;
            }else{
                dealStatus == dealingProgress.JudgeRequested;
                return false;
            }
            
        }
        
    }



    function endJudgement(bytes32 _progress) public onlyWhileDealing returns(bool ended){
        //codes to check if seller and buyer could make a new Mutual Understanding before the deadline then codes to refund the buyer or send currency to the seller
        address judge = getJudgeAdrs();
        if(msg.sender == seller && _progress == sellerAgreementToRefund){
            //callin emergency function to endjudgment
            if(pf.cancelJudge(judge, 4)){
                //updating state variables
                sellerSatisfaction = dealSatisfaction.Satisfied;
                dealStatus = dealingProgress.FailedWithSellerGiveUp;
                winnerSide = judgeStatus.canceled;

                //refund the buyer

                currency == address(0)
                ?sf.safeTransferETH(buyer,amountLessFee)
                :sf.safeTransfer(currency, buyer, amountLessFee);
                
                ended = true;
                }

            
        } else if(msg.sender == buyer && _progress == buyerDisputeWithdrawal){
            //callin emergency function to endjudgment
            if(pf.cancelJudge(judge, 3)){
                //updating state variables

                buyerSatisfaction = dealSatisfaction.Satisfied;
                dealStatus = dealingProgress.wellEndedWithBuyerGiveUp;
                winnerSide = judgeStatus.canceled;

                //send funds to the seller

            currency == address(0)
            ?sf.safeTransferETH(seller,amountLessFee)
            :sf.safeTransfer(currency, seller, amountLessFee);
            ended = true;
            }
            

            
        }

        //codes for ending the judgement on rift hub
 
        if(pf.lockJudgeContract(judge)) IRift(RiftHub).endJudgementUpdate(buyer,seller);
        ended = true; 

    
    }

    function lockBargainAfterJudge(uint8 winner) external onlyWhileDealing onlyRift returns(bool locked){
        dealInProgress = false;

        if(winner == 1) {
            dealStatus = dealingProgress.FailedWithJudgementVote;
            winnerSide = judgeStatus.Buyer;
            }
        else if(winner == 2){
            dealStatus = dealingProgress.WellEndedWithJudgementVote;
            winnerSide = judgeStatus.Seller;
        }
        
        return true;


    }


    }    














 

