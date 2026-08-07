// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;

import '../../lib/DataTypes.sol';

interface IBargainDeployer {
    function newRealBargain(EscrowParams memory params,bytes32 salt) external returns(address bargainAdrs);
}