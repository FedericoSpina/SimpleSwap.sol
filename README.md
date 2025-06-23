# 💰 SimpleSwap: Decentralized Exchange (DEX) Smart Contract

This Solidity smart contract, **SimpleSwap**, implements the core functionalities of a decentralized exchange (DEX). It's designed to replicate the fundamental features found in protocols like Uniswap V2, but within a single, self-contained contract.

> Developed as the final assignment for Module 3, focusing on smart contract implementation, best practices, and code verification.

---

## 📌 Key Features

✅ **Add Liquidity**: Deposit a pair of ERC-20 tokens to receive LP tokens representing your pool share.
✅ **Remove Liquidity**: Burn LP tokens to withdraw your proportional share of underlying tokens.
✅ **Swap Tokens**: Trade one token for another with exchange rates determined by the constant product formula (`x * y = k`).
✅ **Price Discovery**: Query the current spot price of token pairs.
✅ **Amount Calculation**: Calculate expected output tokens for a given input, useful for frontend integration.

---

## 🛠️ How It Works

- **Internal Pool Management**: `SimpleSwap` manages all liquidity pools internally, eliminating the need for separate contracts per token pair.
- **Unique Pool Identifiers**: Each token pair generates a unique `poolId` by sorting token addresses and hashing them.
- **State Management**: The contract efficiently stores token reserves and total liquidity supply for each pool using a `struct`. User-specific liquidity balances are tracked in a separate mapping.
- **Constant Product Formula (x * y = k)**: Swaps are governed by this fundamental DEX principle. A **0.3% fee** is applied to trades, which is then reinvested into the liquidity pool, benefiting liquidity providers.

---

## 🚀 How to Use

Here's a step-by-step guide to interacting with the `SimpleSwap` contract:

### 1. Deploy the Contract

Deploy the `SimpleSwap.sol` contract to an Ethereum-compatible network (e.g., Sepolia, Goerli, or a local development network).

### 2. Approve Tokens

Before you can add liquidity or swap tokens, you must **approve** the `SimpleSwap` contract to spend your ERC-20 tokens. Call the `approve` function on each of the ERC-20 token contracts you intend to use.

#### Example: Approving WETH

| Field               | Value                                     |
| :------------------ | :---------------------------------------- |
| Token Contract      | `WETH.sol` (or any ERC-20 token contract) |
| Function            | `approve(address spender, uint256 amount)` |
| `spender`           | `[Your Deployed SimpleSwap Contract Address]` |
| `amount`            | `[Amount of Tokens to Approve (in wei)]` |

### 3. Interact with SimpleSwap Functions

Once approved, you can call the public functions on your deployed `SimpleSwap` contract.

#### Example: Adding Liquidity

To add WETH and DAI to a pool:

| Function            | `addLiquidity(address tokenA, address tokenB, uint256 amountA, uint256 amountB)` |
| :------------------ | :------------------------------------------------------------------------------- |
| `tokenA`            | `[WETH Contract Address]`                                                        |
| `tokenB`            | `[DAI Contract Address]`                                                         |
| `amountA`           | `[Amount of WETH to Add (in wei)]`                                               |
| `amountB`           | `[Amount of DAI to Add (in wei)]`                                                |

Other functions you can call:

- `removeLiquidity(address tokenA, address tokenB, uint256 lpAmount)`
- `swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address tokenIn, address tokenOut)`
- `getPrice(address tokenA, address tokenB)` (view function)
- `getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)` (pure function)

---

## 🔍 Verification

The `SimpleSwap` contract is designed for full compatibility with the provided `SwapVerifier.sol` contract. It successfully passes all verification checks, including:

-   Adding and removing liquidity
-   Accurate price calculation
-   Correct token swapping mechanics

---
