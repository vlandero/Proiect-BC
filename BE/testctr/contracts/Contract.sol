// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    string public message = "Hello World!";

    function updateMessage(string memory _message) public {
        message = _message;
    }
}