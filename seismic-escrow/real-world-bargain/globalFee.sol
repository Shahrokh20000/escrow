// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;
import '../lib/DataTypes.sol';
import './library/error.sol';
import './library/safeFunctions.sol' as sf;



contract globalFee{
    address public immutable RiftHub;
    modifier onlyRiftHub(){
        if (msg.sender != RiftHub){
            bytes4 selector = OnlyHub.selector;
            assembly{
                mstore(0,shl(224,selector))
            }
        }
        _;
    }

    // mapping(bytes32 => judgeManager) public judges ;
    // //key = judge details slot
    // function updateJudges(bytes32 _slot,judgeManager memory _datails) external onlyRiftHub returns(bool updated){
    //         judges[_slot] = _datails;
    //         return true;
    // }
    function transferCurrency(address _token,address _reciever,uint256 _amount) external returns(bool transfered){
        _token == address(0)
        ?sf.safeTransferETH(_reciever,_amount)
        :sf.safeTransfer(_token,_reciever,_amount);
        return true;
    }

        //codes for a function to update voters settlement if deadline has ended and votes are not equal
    function updateSettlement() public returns(bool updated){
    }
}