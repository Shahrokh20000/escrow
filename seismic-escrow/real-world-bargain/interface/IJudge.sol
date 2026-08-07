// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;


interface IJudge{
    function hasEnded() external view returns(bool);
    function judgeWinner() external view returns(uint8);
    function isUpdatedInRiftHub() external view returns(bool);
    function updateDetailsInRiftHub() external returns(bool);
    function judgeNumberBetweenTheseDealers() external returns(uint256);
    function emergencyJudgeEnding(uint8 _detail) external returns(bool ended);
    function endJudgement() external returns(bool ended);
    function buyer() external view returns(address);
    function seller() external view returns(address);
    function amountForVoter(address _voter) external view returns(uint256 _amount);
    // function winner() public view returns(uint8 val);
}
