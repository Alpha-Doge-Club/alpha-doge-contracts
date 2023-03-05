// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./common/NonReentrancy.sol";
import "./interface/GMXPositionRouter.sol";
import "./interface/GMXRouter.sol";

contract Wallet is NonReentrancy, Context {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public pool;
    address public trader;

    address public positionRouter;
    address public router;
    address public reader;

    constructor(
        address pool_,
        address trader_,
        address positionRouter_,
        address router_,
        address reader_
    ) {
        pool = pool_;
        trader = trader_;
        positionRouter = positionRouter_;
        router = router_;
        reader = reader_;

    }

    modifier onlyPool() {
        require(_msgSender() == pool, "Only pool");
        _;
    }

    modifier onlyTrader() {
        require(_msgSender() == trader, "Only trader");
        _;
    }

    function withdraw(
        address token_,
        address toAddress_,
        uint256 amount_
    ) external onlyPool {
        IERC20(token_).safeTransfer(toAddress_, amount_);
    }

    function approve(
        address token_,
        uint256 amount_
    ) external onlyTrader {
        IERC20(token_).safeApprove(router, amount_);
    }

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external onlyTrader returns (bytes32) {
        GMXPositionRouter(positionRouter).createIncreasePosition(
            _path,
            _indexToken,
            _amountIn,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            _referralCode,
            _callbackTarget
        );
    }

    function createIncreasePositionETH(
        address[] memory _path,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external onlyTrader returns (bytes32) {
        GMXPositionRouter(positionRouter).createIncreasePositionETH(
            _path,
            _indexToken,
            _minOut,
            _sizeDelta,
            _isLong,
            _acceptablePrice,
            _executionFee,
            _referralCode,
            _callbackTarget
        );
    }

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external onlyTrader {
        GMXPositionRouter(positionRouter).createDecreasePosition(
            _path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            _isLong,
            _receiver,
            _acceptablePrice,
            _minOut,
            _executionFee,
            _withdrawETH,
            _callbackTarget
        );
    }

    function approvePlugin(address _plugin) external onlyTrader {
        GMXRouter(router).approvePlugin(_plugin);
    }

    function swap(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address _receiver
    ) external onlyTrader {
        GMXRouter(router).swap(_path, _amountIn, _minOut, _receiver);
    }

    function swapETHToTokens(
        address[] memory _path,
        uint256 _minOut,
        address _receiver
    ) external onlyTrader {
        GMXRouter(router).swapETHToTokens(
            _path, _minOut, _receiver);
    }

    function swapTokensToETH(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        address payable _receiver
    ) external onlyTrader {
        GMXRouter(router).swapTokensToETH(
            _path, _amountIn, _minOut, _receiver);
    }
}
