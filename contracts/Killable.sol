// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Killable {
    address payable public owner;

    constructor () {
      owner = payable(msg.sender);
    }

    function kill() external {
      require(payable(msg.sender) == payable(owner), "Only the owner can kill this contract");
      selfdestruct(payable(owner));
    }
}