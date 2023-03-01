// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

contract PoolModel {

    address public baseToken;

    struct PoolInfo {
        // Base token amount
        uint256 totalShare;
        uint256 pendingShare;
        uint256 amountPerShare;

        // Basic information.
        uint256 lastTime;
        uint256 waitDays;
        uint256 openDays;
        address admin;
        string name;
    }

    PoolInfo[] public poolInfoArray;

    // admin => poolIndex
    mapping(address => uint256) public poolIndexPlusOneMap;

    struct UserInfo {
        // Base token amount
        uint256 share;

        // Pending share (for withdraw)
        uint256 pendingShare;
    }

    // poolIndex => user => UserInfo
    mapping(uint256 => mapping(address => UserInfo)) public userInfoMap;

    struct WithdrawRequest {
        uint256 share;
        uint256 time;
        bool executed;
    }

    // poolIndex => user => WithdrawRequest[]
    mapping(uint256 => mapping(address => WithdrawRequest[])) public
        withdrawRequestMap;
}
