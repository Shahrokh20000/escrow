// SPDX-License-Identifier: MIT
pragma solidity ^0.8.34;
import './error.sol';

    function safeTransfer(address token, address to, uint256 value) {
        // 0xa9059cbb = bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert TransferHelper_TransferFailed();
        }
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) {
        // 0x23b872dd = bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert TransferHelper_TransferFromFailed();
        }
    }

    function safeTransferETH(address to, uint value) {
        (bool success,bytes memory data) = to.call{value: value}(new bytes(0));
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert TransferHelper_EthTransferFailed();
        }
    }
    function safeBalanceOf(address token,address account) view returns (uint256) {
        // 0x70a08231 = bytes4(keccak256(bytes('balanceOf(address)')));
        (bool success,bytes memory data) = token.staticcall(abi.encodeWithSelector(0x70a08231,account));
        if (!success) {
            revert TransferHelper_BalanceOfFailed();
        }
        return abi.decode(data, (uint256));
    }

    function selfETHBalance() view returns(uint256 bal){
            assembly{
                bal := selfbalance()
            }
        }
    
    function safeTransferFromNFT(address nft , address from , address to , uint256 id) {
        // 0x23b872dd = bytes4(keccak256("transferFrom(address,address,uint256)"));

        (bool success ,bytes memory data) = nft.call(abi.encodeWithSelector(0x23b872dd, from,to,id));
        if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
            revert NFTTransferFailed();
        }
        
    }

    function safeCheckOwner(address nft , uint256 id ) view returns(address){
        (bool success,bytes memory data) = nft.staticcall(abi.encodeWithSelector(0x6352211e, id));
        if(!success ){
            revert CheckNFTBalanceFailed();
        }
        return abi.decode(data,(address));
    }

    // function safeTransferNFT(address nft,address from,address to,uint256 id){
    //     // 0xa9059cbb = bytes4(keccak256("transfer(address,uint256)"));
    //     (bool success ,bytes memory data) = nft.call(abi.encodeWithSelector(0xa9059cbb,from,to,id));
    //     if (!success || (data.length > 0 && !abi.decode(data, (bool)))) {
    //         revert NFTTransferFailed();
    //     }
    // }
