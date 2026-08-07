// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;

import '../lib/DataTypes.sol';
import '../lib/safeFunctions.sol' as sf;
import '../lib/error.sol';



contract bargain{


    mapping(bytes32 => dealPair) public bargains;
    //one sloted (buyer,seller,dealNumber)
    mapping (bytes32 => dealer) public dealers;
    //one sloted (buyer,seller)

    function propose(cryptoDeal memory collateralized,cryptoDeal memory expecting,uint256 deadline) public payable returns(bytes32 detailSlot){
        
        {if(collateralized.tokens.length > 10 || collateralized.nfts.length > 10 || expecting.tokens.length > 10 || expecting.nfts.length > 10) revert TooMuchAssets();}

        //codes for transfering native
        {
            if(msg.value != collateralized.native){
                revert NativeNotExpected();
            }
        }

            //codes for transfering nfts
            {
            for(uint8 i;i < collateralized.nfts.length;i++){
            address nft = collateralized.nfts[i].nft;
            uint256 id = collateralized.nfts[i].id;

            sf.safeTransferFromNFT(nft, collateralized.dealer, address(this), id);

            if(sf.safeCheckOwner(nft, id) != address(this)) revert OwnershipTransferFailed();

        }
            }

        //codes for transfering tokens
            {
            for(uint8 i;i < collateralized.tokens.length;i++){
            address token = collateralized.tokens[i].token;
            uint256 amount = collateralized.tokens[i].amount;
            uint256 beforeAmount = sf.safeBalanceOf(token, address(this));
            sf.safeTransferFrom(token, collateralized.dealer, address(this), amount);
            uint256 afterAmount = sf.safeBalanceOf(token, address(this));

            if(afterAmount - beforeAmount != amount){
                revert OwnershipTransferFailed();
            }

        }
            }


    {
       (address _0 , address _1) =
        collateralized.dealer > expecting.dealer
        ?(expecting.dealer,collateralized.dealer)
        :(collateralized.dealer,expecting.dealer);

        bytes32 dealerSlot;
        assembly{
            let truncatedBuyer := shr(64,_0)
            let shiftedSeller := shl(96,_1)
            dealerSlot := or(truncatedBuyer,shiftedSeller)
        }

        dealers[dealerSlot].dealNumber ++;
        uint256 num = dealers[dealerSlot].dealNumber;
        
        assembly{
            let ptr := mload(0x40)
            mstore(ptr,_0)
            mstore(add(ptr,32),_1)
            mstore(add(ptr,64),num)
            detailSlot := keccak256(ptr,96)
        }
        }
        dealPair memory _pair;
        _pair.listener = expecting;
        _pair.caller = collateralized;
        _pair.deadline = deadline;
        _pair.settled = 3 << 6;

        bargains[detailSlot] = _pair;
        
    }

    function respond(bytes32 detailSlot) public payable returns(bool done){
        dealPair memory _pair = bargains[detailSlot];
        {
            if(msg.value != _pair.listener.native){
                revert NativeNotExpected();
            }
        }

        //codes for transfering nfts
            {
            for(uint8 i;i < _pair.listener.nfts.length;i++){
            address nft = _pair.listener.nfts[i].nft;
            uint256 id = _pair.listener.nfts[i].id;

            sf.safeTransferFromNFT(nft, _pair.listener.dealer, address(this), id);

            if(sf.safeCheckOwner(nft, id) != address(this)) revert OwnershipTransferFailed();

        }
            }

        //codes for transfering tokens
            {
            for(uint8 i;i < _pair.listener.tokens.length;i++){
            address token = _pair.listener.tokens[i].token;
            uint256 amount = _pair.listener.tokens[i].amount;
            uint256 beforeAmount = sf.safeBalanceOf(token, address(this));
            sf.safeTransferFrom(token, _pair.listener.dealer, address(this), amount);
            uint256 afterAmount = sf.safeBalanceOf(token, address(this));

            if(afterAmount - beforeAmount != amount){
                revert OwnershipTransferFailed();
            }

        }
            
            }

        _pair.settled = 48 | _pair.settled;

        bargains[detailSlot] = _pair;

        
        return true;
    }

    function settleCaller(bytes32 _slot) public returns(bool settled){
        dealPair memory _pair = bargains[_slot];
        uint8 condition = (3 << 2) & _pair.settled;
        if(_pair.settled >= 239 && _pair.detail != 1 && condition == 0 ){
            _pair.detail = 2;
            _pair.settled = 12 | _pair.settled;
            bargains[_slot] = _pair;
            //transfering assets & ending the deal
            address caller = _pair.caller.dealer;

            {

            sf.safeTransferETH(caller,_pair.listener.native);

            }
            
            {

            for(uint8 i;i < _pair.listener.nfts.length;i++){
            address nft = _pair.listener.nfts[i].nft;
            uint256 id = _pair.listener.nfts[i].id;

            sf.safeTransferFromNFT(nft,address(this),caller , id);

            if(sf.safeCheckOwner(nft, id) != caller) revert OwnershipTransferFailed();

                }

            }

            {

            for(uint8 i;i < _pair.listener.tokens.length;i++){
            address token = _pair.listener.tokens[i].token;
            uint256 amount = _pair.listener.tokens[i].amount;
            uint256 beforeAmount = sf.safeBalanceOf(token, caller);
            sf.safeTransfer(token, caller, amount);
            uint256 afterAmount = sf.safeBalanceOf(token, caller);

            if(afterAmount - beforeAmount != amount){
                revert OwnershipTransferFailed();
                }

                    }
            
            }

            settled = true;





        }
        else{
            //codes for reverting
            revert SettlementFailed();
        }

    }

    function settleListener(bytes32 _slot) public returns(bool settled){
        dealPair memory _pair = bargains[_slot];
        uint8 condition = 3 & _pair.settled;



        if(_pair.settled >= 239 && _pair.detail != 1 && condition == 0 ){
            _pair.detail = 2;
            _pair.settled = 3 | _pair.settled;
            bargains[_slot] = _pair;
            //transfering assets & ending the deal
            address listener = _pair.listener.dealer;
            
            {

            sf.safeTransferETH(listener,_pair.caller.native);

            }


            {

            for(uint8 i;i < _pair.caller.nfts.length;i++){
            address nft = _pair.caller.nfts[i].nft;
            uint256 id = _pair.caller.nfts[i].id;

            sf.safeTransferFromNFT(nft,address(this),listener , id);

            if(sf.safeCheckOwner(nft, id) != listener) revert OwnershipTransferFailed();

                }

            }

            {

            for(uint8 i;i < _pair.caller.tokens.length;i++){
            address token = _pair.caller.tokens[i].token;
            uint256 amount = _pair.caller.tokens[i].amount;
            uint256 beforeAmount = sf.safeBalanceOf(token, listener);
            sf.safeTransfer(token, listener, amount);
            uint256 afterAmount = sf.safeBalanceOf(token, listener);

            if(afterAmount - beforeAmount != amount){
                revert OwnershipTransferFailed();
                }

                    }
            
            }



            settled = true;





        }
        else{
            //codes for reverting
            revert SettlementFailed();
        }

    }


    function cancel(bytes32 _slot) public returns(bool canceled){
        
        dealPair memory _pair = bargains[_slot];
        if(((msg.sender == _pair.caller.dealer || msg.sender == _pair.listener.dealer) || block.timestamp > _pair.deadline ) && (_pair.detail == 0 && _pair.settled < 243)){
            {
            bargains[_slot].detail = 1;
            }
            address listener = _pair.listener.dealer;
            address caller = _pair.caller.dealer;
            
            //caller refund start
            uint8 condition = (3 << 6) & _pair.settled;
            if(condition != 0){

            {

            if(_pair.caller.native > 0)sf.safeTransferETH(caller,_pair.caller.native);

            }

            {

            for(uint8 i;i < _pair.caller.nfts.length;i++){
            address nft = _pair.caller.nfts[i].nft;
            uint256 id = _pair.caller.nfts[i].id;

            sf.safeTransferFromNFT(nft,address(this),caller , id);

            if(sf.safeCheckOwner(nft, id) != caller) revert OwnershipTransferFailed();

                }

            }

            {

            for(uint8 i;i < _pair.caller.tokens.length;i++){
            address token = _pair.caller.tokens[i].token;
            uint256 amount = _pair.caller.tokens[i].amount;
            uint256 beforeAmount = sf.safeBalanceOf(token, caller);
            sf.safeTransfer(token, caller, amount);
            uint256 afterAmount = sf.safeBalanceOf(token, caller);

            if(afterAmount - beforeAmount != amount){
                revert OwnershipTransferFailed();
                }

                    }
            
            }
            //caller refund end

            //listener refund start
            condition = (3 << 4) & _pair.settled;

            if(condition != 0){
                {

            if(_pair.listener.native > 0)sf.safeTransferETH(listener,_pair.listener.native);

            }

            {

            for(uint8 i;i < _pair.listener.nfts.length;i++){
            address nft = _pair.listener.nfts[i].nft;
            uint256 id = _pair.listener.nfts[i].id;

            sf.safeTransferFromNFT(nft,address(this), listener , id);

            if(sf.safeCheckOwner(nft, id) != listener) revert OwnershipTransferFailed();

                }

            }

            {

            for(uint8 i;i < _pair.listener.tokens.length;i++){
            address token = _pair.listener.tokens[i].token;
            uint256 amount = _pair.listener.tokens[i].amount;
            uint256 beforeAmount = sf.safeBalanceOf(token, listener);
            sf.safeTransfer(token, listener, amount);
            uint256 afterAmount = sf.safeBalanceOf(token, listener);

            if(afterAmount - beforeAmount != amount){
                revert OwnershipTransferFailed();
                }

                    }
            
            }
            }
            }

            
            //listener refund end

            // updating global variables

            _pair.settled = 0;
            _pair.detail = 1 ; //means as canceled
            bargains[_slot] = _pair;

            canceled = true;


        } else {
            canceled = false;
        }

        
    }
}