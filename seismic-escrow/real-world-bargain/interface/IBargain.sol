// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import '../../lib/DataTypes.sol';

interface IBargain {

    function filterVoters(address _voter) external view returns(bool);
    function buyer() external view returns (address);
    function seller() external view returns (address);
    function dealNumber () external view returns (uint256);
    function getJudgeAdrs() external view returns(address adrs);
    function BARGAIN_KEY() external view returns(bytes32);
    function dealStatus() external view returns (dealingProgress);
    function judgeIncentive() external view returns(uint256);
    function currency() external view returns (address);

    
    
}