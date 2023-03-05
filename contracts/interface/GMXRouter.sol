// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface GMXRouter {

    function approvePlugin(address _plugin) external;

    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function swapETHToTokens(address[] memory _path, uint256 _minOut, address _receiver) external;

    function swapTokensToETH(address[] memory _path, uint256 _amountIn, uint256 _minOut, address payable _receiver) external;
}
