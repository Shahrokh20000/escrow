// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;
import '../../lib/DataTypes.sol';

interface IGlobalFee {
    function updateJudges(bytes32 _slot,judgeManager memory _datails) external returns(bool updated);
    function transferCurrency(address _token,address _reciever,uint256 _amount) external returns(bool transfered);
}