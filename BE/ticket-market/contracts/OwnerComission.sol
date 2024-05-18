// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./Withdrawable.sol";

contract OwnerComission is Withdrawable {
    using SafeMath for uint256;

    address private owner;

    event ComissionChanged(uint256 comission);

    function addComission (uint256 _comission) external onlyOwner {
        _addToPendingWithdrawal(owner, _comission);
    }

    function withdrawComission() public onlyOwner {
        withdraw();
    }

    function getPendingComission() external onlyOwner view returns (uint256) {
        return getPendingWithdrawal(owner);
    }
    constructor() {
        owner = msg.sender;
    }
}