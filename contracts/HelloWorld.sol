//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract HelloWorld {
  string private HelloMeassge = "Hello World";
  function sayHello() public view returns (string memory) {
    return HelloMeassge;
  }
}