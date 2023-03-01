// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./model/PoolModel.sol";
import "./common/NonReentrancy.sol";

contract Pool is PoolModel, NonReentrancy, Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
 
    uint256 constant SHARE_UNITS = 1e18;
    uint256 constant AMOUNT_PER_SHARE = 1e18;
    uint256 constant RATIO_BASE = 1e6;

    uint256 constant MIN_WAIT_DAYS = 6;
    uint256 constant MIN_OPEN_DAYS = 1;

    event Deposit(
        uint256 indexed poolIndex_,
        address indexed who_,
        uint256 amount_
    );

    event Withdraw(
        uint256 indexed poolIndex_,
        address indexed who_,
        uint256 share_
    );

    event WithdrawReady(
        uint256 indexed poolIndex_,
        address indexed who_,
        uint256 indexed requestIndex_,
        uint256 share_,
        uint256 amount_
    );

    // ** Pool config.

    function getPoolInfoArrayLength() external view returns(uint256) {
        return poolInfoArray.length;
    }

    function getPoolByIndex(uint256 poolIndex_) external view returns(
        PoolInfo memory
    ) {
        return poolInfoArray[poolIndex_];
    }

    function getPoolByAdmin(address admin_) external view returns(
        PoolInfo memory
    ) {
        uint256 indexPlusOne = poolIndexPlusOneMap[admin_];
        require(indexPlusOne > 0, "Invalid index");
        return poolInfoArray[indexPlusOne.sub(1)];
    }

    function createPool(
        uint256 waitDays_,
        uint256 openDays_,
        string calldata name_
    ) external {
        require(waitDays_ >= MIN_WAIT_DAYS, "Not enough wait days");
        require(openDays_ >= MIN_OPEN_DAYS, "Not enough wait days");

        poolInfoArray.push(PoolInfo({
            totalShare: 0,
            pendingShare: 0,
            amountPerShare: AMOUNT_PER_SHARE,
            lastTime: 0,
            waitDays: waitDays_,
            openDays: openDays_,
            admin: _msgSender(),
            name: name_
        }));

        poolIndexPlusOneMap[_msgSender()] = poolInfoArray.length;
    }

    function startPool() external {
        uint256 indexPlusOne = poolIndexPlusOneMap[_msgSender()];
        require(indexPlusOne > 0, "Invalid index");

        PoolInfo storage poolInfo = poolInfoArray[indexPlusOne.sub(1)];
        require(poolInfo.lastTime == 0, "Already started");
        require(poolInfo.admin == _msgSender(), "Not admin");

        poolInfo.lastTime = now;
    }

    // ** Regular operations.
    function deposit(
        uint256 poolIndex_,
        uint256 amount_
    ) external noReenter {
        require(poolIndex_ < poolInfoArray.length, "Invalid index");
        PoolInfo storage poolInfo = poolInfoArray[poolIndex_];

        if (poolInfo.lastTime > 0) {
            uint256 windowStartAt = poolInfo.lastTime.add(
                poolInfo.waitDays.mul(1 days));
            uint256 windowCloseAt = windowStartAt.add(
                poolInfo.openDays.mul(1 days));

            require(now > windowStartAt && now < windowCloseAt,
                "Should be in window");
        }

        require(amount_ >= AMOUNT_PER_SHARE / 1000000, "Less than minimum");

        IERC20(baseToken).safeTransferFrom(
            _msgSender(), address(this), amount_);

        UserInfo storage userInfo = userInfoMap[poolIndex_][_msgSender()];

        uint256 shareToAdd =
            amount_.mul(SHARE_UNITS).div(poolInfo.amountPerShare);
        poolInfo.totalShare = poolInfo.totalShare.add(shareToAdd);
        userInfo.share = userInfo.share.add(shareToAdd);

        emit Deposit(poolIndex_, _msgSender(), amount_);
    }

    // Called before window
    function withdraw(
        uint256 poolIndex_,
        uint256 share_
    ) external {
        require(poolIndex_ < poolInfoArray.length, "Invalid index");
        PoolInfo storage poolInfo = poolInfoArray[poolIndex_];

        if (poolInfo.lastTime > 0) {
            uint256 windowStartAt = poolInfo.lastTime.add(
                poolInfo.waitDays.mul(1 days));
            
            require(now < windowStartAt, "Should be before window");
        }

        UserInfo storage userInfo = userInfoMap[poolIndex_][_msgSender()];

        require(share_ <= userInfo.share, "Not enough shares");

        withdrawRequestMap[poolIndex_][_msgSender()].push(WithdrawRequest({
            share: share_,
            time: now,
            executed: false
        }));

        emit Withdraw(poolIndex_, _msgSender(), share_);
    }

    // Called during window
    function withdrawReady(
        uint256 poolIndex_,
        address who_,
        uint256 requestIndex_
    ) external noReenter {
        require(poolIndex_ < poolInfoArray.length, "Invalid index");
        PoolInfo storage poolInfo = poolInfoArray[poolIndex_];

        if (poolInfo.lastTime > 0) {
            uint256 windowStartAt = poolInfo.lastTime.add(
                poolInfo.waitDays.mul(1 days));
            uint256 windowCloseAt = windowStartAt.add(
                poolInfo.openDays.mul(1 days));

            require(now > windowStartAt && now < windowCloseAt,
                "Should be in window");
        }

        require(requestIndex_ < withdrawRequestMap[poolIndex_][who_].length,
            "No request index");

        WithdrawRequest storage request =
            withdrawRequestMap[poolIndex_][who_][requestIndex_];

        require(!request.executed, "Already executed");

        UserInfo storage userInfo = userInfoMap[poolIndex_][who_];
        userInfo.share = userInfo.share.sub(request.share);

        uint256 amount = poolInfo.amountPerShare.mul(request.share);
        IERC20(baseToken).safeTransfer(_msgSender(), amount);

        request.executed = true;

        emit WithdrawReady(
            poolIndex_, _msgSender(), requestIndex_, request.share, amount);
    }

    function withdrawRequestCount(
        uint256 poolIndex_,
        address who_
    ) external view returns(uint256) {
        return withdrawRequestMap[poolIndex_][who_].length;
    }
}
