// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import '../../lib/DataTypes.sol';
interface IUser {
    function profile() external view returns(profileStruct memory _profile);
    function registrationTime() external view returns(uint256 _time);
        function updateProfile(profileStruct memory _profile ,address _creditorToken,int256 _creditorTokenAmount,bool updateSettle) external returns(bool updated);
}