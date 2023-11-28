// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract MockOracle {
    function getPrice() public pure returns(uint256){
        return 10000;
    }
}