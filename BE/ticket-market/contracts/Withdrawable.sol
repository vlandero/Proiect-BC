// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Withdrawable {
    using SafeMath for uint256;
    mapping(address => uint256) public _pendingWithdrawals;
    
    event Withdrawal(address indexed user, uint256 amount);
    event Received(address indexed user, uint256 amount);

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyOwnerOrCreator(address creator) {
        require(msg.sender == owner || msg.sender == creator, "Only owner or creator can call this function");
        _;
    }

    function withdraw() public payable {
        uint256 amount = _pendingWithdrawals[msg.sender];
        require(amount > 0, "No pending withdrawal");
        _pendingWithdrawals[msg.sender] = 0;
        address payable payableAddress = payable(msg.sender);
        (payableAddress).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function getPendingWithdrawal(address user) public onlyOwnerOrCreator(user) view returns (uint256) {
        return _pendingWithdrawals[user];
    }

    function _addToPendingWithdrawal(address user, uint256 amount) internal {
        _pendingWithdrawals[user] += amount;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}
