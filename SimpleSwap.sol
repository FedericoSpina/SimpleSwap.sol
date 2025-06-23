// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title SimpleSwap
 * @author Federico S.
 * @notice Basic Automated Market Maker (AMM) contract allowing:
 *         - Liquidity provision and removal
 *         - Token swaps based on constant product formula
 *         - Output estimation and price inspection
 * @dev This contract issues LP tokens via the ERC20 "Pool Share Token" (PST)
 */
contract SimpleSwap is ERC20 {
    using Math for uint256;

    /// @dev Struct representing a liquidity pool for a token pair
    struct LiquidityPool {
        uint256 reserveA;
        uint256 reserveB;
        uint256 totalLiquidity;
    }

    /// @notice Mapping of token pair hash to liquidity pool data
    mapping(bytes32 => LiquidityPool) public pairPools;

    /// @notice Initializes the LP token as "Pool Share Token" (PST)
    constructor() ERC20("Pool Share Token", "PST") {}

    /**
     * @notice Computes a unique hash for a token pair (order-independent)
     * @param tokenX First token address
     * @param tokenY Second token address
     * @return Hash of the token pair
     */
    function _pairHash(address tokenX, address tokenY)
        internal
        pure
        returns (bytes32)
    {
        (address tMin, address tMax) = tokenX < tokenY
            ? (tokenX, tokenY)
            : (tokenY, tokenX);
        return keccak256(abi.encodePacked(tMin, tMax));
    }

    //================
    // FUNCTION 1 - ADD LIQUIDITY
    //================

    /**
     * @notice Adds liquidity to the pool and mints LP tokens
     * @param tokenA Address of token A
     * @param tokenB Address of token B
     * @param amountADesired Desired amount of token A to add
     * @param amountBDesired Desired amount of token B to add
     * @param amountAMin Minimum amount of token A to add
     * @param amountBMin Minimum amount of token B to add
     * @param to Address to receive LP tokens
     * @param deadline Unix timestamp after which the transaction is invalid
     * @return amountASent Final amount of token A deposited
     * @return amountBSent Final amount of token B deposited
     * @return liquidity Amount of LP tokens minted
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        public
        returns (
            uint256 amountASent,
            uint256 amountBSent,
            uint256 liquidity
        )
    {
        require(block.timestamp <= deadline, "Transaction expired");

        bytes32 poolId = _pairHash(tokenA, tokenB);
        LiquidityPool storage pool = pairPools[poolId];

        if (pool.totalLiquidity == 0) {
            amountASent = amountADesired;
            amountBSent = amountBDesired;
            liquidity = Math.sqrt(amountASent * amountBSent);
        } else {
            uint256 optimalB = (amountADesired * pool.reserveB) / pool.reserveA;

            if (optimalB <= amountBDesired) {
                require(optimalB >= amountBMin, "Too much slippage on B");
                amountASent = amountADesired;
                amountBSent = optimalB;
            } else {
                uint256 optimalA = (amountBDesired * pool.reserveA) /
                    pool.reserveB;
                require(optimalA >= amountAMin, "Too much slippage on A");
                amountASent = optimalA;
                amountBSent = amountBDesired;
            }

            liquidity = Math.min(
                (amountASent * pool.totalLiquidity) / pool.reserveA,
                (amountBSent * pool.totalLiquidity) / pool.reserveB
            );
        }

        require(liquidity > 0, "Zero liquidity generated");

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountASent);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBSent);

        pool.reserveA += amountASent;
        pool.reserveB += amountBSent;
        pool.totalLiquidity += liquidity;

        _mint(to, liquidity);

        return (amountASent, amountBSent, liquidity);
    }

    //================
    // FUNCTION 2 -  REMOVE LIQUIDITY
    //================

    /**
     * @notice Removes liquidity from the pool and burns LP tokens
     * @param tokenA Address of token A
     * @param tokenB Address of token B
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of token A to receive
     * @param amountBMin Minimum amount of token B to receive
     * @param to Address to receive withdrawn tokens
     * @param deadline Unix timestamp after which the transaction is invalid
     * @return amountASent Amount of token A sent to user
     * @return amountBSent Amount of token B sent to user
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public returns (uint256 amountASent, uint256 amountBSent) {
        require(block.timestamp <= deadline, "Transaction expired");
        require(balanceOf(msg.sender) >= liquidity, "Not enough LP tokens");

        bytes32 poolId = _pairHash(tokenA, tokenB);
        LiquidityPool storage pool = pairPools[poolId];

        amountASent = (liquidity * pool.reserveA) / pool.totalLiquidity;
        amountBSent = (liquidity * pool.reserveB) / pool.totalLiquidity;

        require(amountASent >= amountAMin, "Too much slippage on A");
        require(amountBSent >= amountBMin, "Too much slippage on B");

        pool.reserveA -= amountASent;
        pool.reserveB -= amountBSent;
        pool.totalLiquidity -= liquidity;

        _burn(msg.sender, liquidity);

        IERC20(tokenA).transfer(to, amountASent);
        IERC20(tokenB).transfer(to, amountBSent);

        return (amountASent, amountBSent);
    }

    //================
    // FUNCTION 3 - SWAP EXACT TOKENS FOR TOKENS
    //================

    /**
     * @notice Swaps a fixed amount of tokens for another token in the pair
     * @param amountIn Amount of input token to swap
     * @param amountOutMin Minimum acceptable amount of output tokens
     * @param path Array with input and output token addresses [tokenIn, tokenOut]
     * @param to Address to receive output tokens
     * @param deadline Unix timestamp after which the transaction is invalid
     */
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        require(block.timestamp <= deadline, "Transaction expired");
        require(path.length == 2 && amountIn > 0, "Invalid swap path");

        bytes32 poolId = _pairHash(path[0], path[1]);
        LiquidityPool storage pool = pairPools[poolId];
        require(pool.totalLiquidity > 0, "No liquidity available");

        uint256 reserveIn = pool.reserveA;
        uint256 reserveOut = pool.reserveB;

        uint256 outputAmount = getAmountOut(amountIn, reserveIn, reserveOut);
        require(outputAmount >= amountOutMin, "Output too low");

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[1]).transfer(to, outputAmount);

        pool.reserveA += amountIn;
        pool.reserveB -= outputAmount;
    }

    //================
    // FUNCTION 4 - GET PRICE
    //================
    /**
     * @notice Returns the current price of tokenB in terms of tokenA
     * @param tokenA Address of base token
     * @param tokenB Address of quote token
     * @return price Quote: how many tokenB per 1 tokenA (scaled by 1e18)
     */
    function getPrice(address tokenA, address tokenB)
        external
        view
        returns (uint256 price)
    {
        bytes32 poolId = _pairHash(tokenA, tokenB);
        LiquidityPool storage pool = pairPools[poolId];
        require(
            pool.reserveA > 0 && pool.reserveB > 0,
            "No liquidity available, its not possible to get a price."
        );

        price = (pool.reserveB * 1e18) / pool.reserveA;
    }

    //================
    // FUNCTION 5 -  GET AMOUNT OUT
    //================

    /**
     * @notice Estimates the output token amount for a given input
     * @param amountIn Amount of input tokens
     * @param reserveIn Input token reserve
     * @param reserveOut Output token reserve
     * @return amountOut Estimated amount of output tokens
     */
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {
        require(
            amountIn > 0 && reserveIn > 0 && reserveOut > 0,
            "Invalid input, try again."
        );
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
    }
}
