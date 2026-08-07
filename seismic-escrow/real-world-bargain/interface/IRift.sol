// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

interface IRift {
    function startJudgementUpdate() external returns(uint256);
    function endJudgementUpdate(address buyer , address seller) external returns(bool updated);
    function accounts(address _user) external view returns(address _account);
    function hasSettled(address) external view returns(bool);

}