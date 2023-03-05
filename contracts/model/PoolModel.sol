// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract PoolModel {

    address public baseToken;

    // For test.
    bool public isTest;

    struct PoolInfo {
        // Base token amount
        uint256 totalShare;
        uint256 pendingShare;
        uint256 amountPerShare;
        address wallet;

        // Basic information.
        uint256 lastTime;
        uint256 waitDays;
        uint256 gapDays;
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

    // Time control.
    uint256 public timeExtra;

    address public positionRouter;
    address public router;
    address public reader;
}
