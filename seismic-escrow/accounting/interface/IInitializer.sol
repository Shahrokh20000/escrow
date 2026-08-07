// SPDX-License-Identifier: MIT
pragma solidity 0.8.34;
interface IInitializer {
    function createAccount(string memory _username) external returns(address account);
}