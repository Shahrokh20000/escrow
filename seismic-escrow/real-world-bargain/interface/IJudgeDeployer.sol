// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import '../../lib/DataTypes.sol';

interface IJudgeDeployer {
    function createJudge(judgeFrame memory params,address bargainContract) external returns(address);
}