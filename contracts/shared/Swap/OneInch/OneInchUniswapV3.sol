// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {ISwapper} from "../interfaces/ISwapper.sol";

interface IUniswapV3Router {
  function uniswapV3Swap(
    uint256 amount,
    uint256 minReturn,
    uint256[] calldata pools
  ) external payable returns (uint256 returnAmount);
}

/**
 * @title OneInchUniswapV3
 * @notice Swapper contract for 1inch UniswapV3 swaps.
 */
contract OneInchUniswapV3 is ISwapper {
  using Address for address;

  IUniswapV3Router public immutable oneInchUniRouter;

  constructor(address _oneInchUniRouter) {
    oneInchUniRouter = IUniswapV3Router(_oneInchUniRouter);
  }

  /**
   * @notice Swap the given amount of tokens using 1inch.
   * @dev Decode the passed in data and re-encode it with the correct amountIn. This is because the amountIn is not known
   * until the funds are transferred to this contract.
   * @param _amountIn Amount of tokens to swap.
   * @param _fromAsset Address of the token to swap from.
   * @param _toAsset Address of the token to swap to.
   * @param _swapData Data to pass to the 1inch aggregator router.
   */
  function swap(
    uint256 _amountIn,
    address _fromAsset,
    address _toAsset,
    bytes calldata _swapData // from 1inch API
  ) public payable override returns (uint256 amountOut) {
    // transfer the funds to be swapped from the sender into this contract
    TransferHelper.safeTransferFrom(_fromAsset, msg.sender, address(this), _amountIn);
    // decode the swap data
    // https://docs.1inch.io/docs/aggregation-protocol/smart-contract/UnoswapV3Router#uniswapv3swap
    (, uint256 _minReturn, uint256[] memory _pools) = abi.decode(_swapData, (uint256, uint256, uint256[]));

    // Set up swap params
    // Approve the swapper if needed
    if (IERC20(_fromAsset).allowance(address(this), address(oneInchUniRouter)) < _amountIn) {
      TransferHelper.safeApprove(_fromAsset, address(oneInchUniRouter), type(uint256).max);
    }

    // The call to `uniswapV3Swap` executes the swap.
    // use actual amountIn that was sent to the xReceiver
    amountOut = oneInchUniRouter.uniswapV3Swap(_amountIn, _minReturn, _pools);

    // transfer the swapped funds back to the sender
    TransferHelper.safeTransfer(_toAsset, msg.sender, amountOut);
  }
}
