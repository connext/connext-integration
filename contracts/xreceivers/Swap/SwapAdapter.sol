//SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/utils/Address.sol";

import {ISwapper} from "./interfaces/ISwapper.sol";

contract SwapAdapter {
  using Address for address;
  using Address for address payable;

  mapping(address => bool) public allowedSwappers;

  address public immutable uniswapSwapRouter = address(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  constructor() {
    allowedSwappers[address(this)] = true;
    allowedSwappers[uniswapSwapRouter] = true;
  }

  /// Payable
  receive() external payable virtual {}

  /// TODO: Need to implement max-approve to avoid calling approve for every swap.
  /// And then safety checks around it.
  /// TODO: Add function to whitelist swappers
  /// TODO: Add function to remove whitelisted swappers
  /// TODO: Add roles for admin
  /// TODO: Make the contract ownable
  /// TODO: ...

  function exactSwap(
    address _swapper,
    uint256 _amountIn,
    address _fromAsset,
    bytes calldata _swapData // comes directly from API with swap data encoded
  ) public payable returns (uint256 amountOut) {
    require(allowedSwappers[_swapper], "!allowedSwapper");
    amountOut = ISwapper(_swapper).swap(_swapper, _amountIn, _fromAsset, _swapData);
  }

  function directSwapperCall(
    address _swapper,
    bytes calldata swapData,
    uint256 value
  ) public payable returns (uint256) {
    bytes memory ret = _swapper.functionCallWithValue(swapData, value, "!directSwapperCallFailed");
    return abi.decode(ret, (uint256));
  }
}
