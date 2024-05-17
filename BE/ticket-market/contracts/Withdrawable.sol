// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Withdrawable {
    mapping(address => uint256) private _pendingWithdrawals;
    uint256 private _ownerPendingWithdrawal;

    event Withdrawal(address indexed user, uint256 amount);

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function withdraw() external {
        uint256 amount = _pendingWithdrawals[msg.sender];
        require(amount > 0, "No pending withdrawal");
        _pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function withdrawOwner() external onlyOwner {
        uint256 amount = _ownerPendingWithdrawal;
        require(amount > 0, "No pending withdrawal");
        _ownerPendingWithdrawal = 0;
        payable(owner).transfer(amount);
        emit Withdrawal(owner, amount);
    }

    function addToOwnerPendingWithdrawal(uint256 amount) public {
        _ownerPendingWithdrawal += amount;
    }

    function getOwnerPendingWithdrawal() public onlyOwner view returns (uint256) {
        return _ownerPendingWithdrawal;
    }

    function getPendingWithdrawal(address user) public view returns (uint256) {
        return _pendingWithdrawals[user];
    }

    function _addToPendingWithdrawal(address user, uint256 amount) internal {
        _pendingWithdrawals[user] += amount;
    }
}
