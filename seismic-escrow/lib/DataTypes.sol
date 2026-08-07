// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

struct EscrowParams {
        address buyer;
        address seller;
        uint256 bargainDeadline;
        uint256 votingDeadline;
        bool customAddress;
        string ifpsHash;
        bytes32 merkleRoot;
        bool advanced;
        address customFilterInterface;
        bool basicFilter;
        address currency;
        uint256 amount;
        uint256 deadline;
        uint256 voterBalance;
        uint256 voterStakedBalance;
        uint256 voterNativeBalance;
        uint256 minAge;
        uint256 minSuccessJudges;
        uint256 judgeIncentive;
        address dealStarter;
        address globalFeeManager;
    }

        enum dealSatisfaction{
        Waiting,
        Satisfied,
        JudgeRequest
    }

    enum dealingProgress{
        NoProgressShare,
        OnlySellerConfirmed,
        WellEnded,
        JudgeRequested,
        WaitingForJudgement,
        FailedWithSellerGiveUp,
        wellEndedWithBuyerGiveUp,
        FailedWithJudgementVote, //seller didn't take funds
        WellEndedWithJudgementVote // seller took funds
    }


    struct agreement{
        bool buyerConfirmed;
        bool sellerConfirmed;
        uint240 dealStartTime;
    }

       enum judgeStatus{
        Ongoing,
        Buyer,
        Seller,
        NoJudge,
        canceled
    }

    struct judgeFrame{
    address RiftHub;
    uint256 defaultDeadline ;
    address seller;
    address buyer;
    uint256 dealNumber;
    address bargainContract;
    uint256 amount;
    uint256 judgeNumberBetweenTheseDealers;
} 

struct dealer {
    address buyer;
    address seller;
    uint24 dealNumber;
}
struct judgeTimes{
    address buyer;
    address seller;
    uint24 judgeNumber;
}
struct judgeDetail{
    bytes32 bargainKey;
    address judge;
    uint8 winner; // 0 for no result yet , 1 for buyer , 2 for seller, 3 judge canceled by buyer , 4 judge canceled by seller
}

struct profileStruct {
    address wallet;
    string username;
    int256 stakedBalance;    
    uint32 totalVotes;          
    uint32 successfulVotes;

}
struct creditorStructure{
    int240 tokenMultiplier; // one less sload optimization
    bool addedToCreditors;
}

struct judgeManager{
    address bargain;
    uint256 incentive;
    address token;
    bool winner; //1 for buyer , 2 for seller
    }


struct ERC20{
    address token;
    uint256 amount;
}

struct ERC721{
    address nft;
    uint256 id;
}

struct cryptoDeal{
    address dealer;
    ERC20[] tokens;
    ERC721[] nfts;
    uint256 native;
}
struct dealPair{
    cryptoDeal caller;
    cryptoDeal listener;
    uint256 deadline;
    uint8 settled;//11000000 if only caller settled with rift, 00110000 if only listener settled with rift , 11110000 if both settled with rift
                //  11111100 if only caller settled totally , 11110011  if only listener settled totally , 11111111 if both settled totally
    uint8 detail; //0 in progress , 1 canceled , 2 ended successfuly 

}

