# SimpleSwap Project

## Overview

**SimpleSwap** is a Solidity smart contract that implements the core functionalities of a decentralized exchange (DEX). It is designed to replicate some of the basic features of protocols like Uniswap V2 but within a single, self-contained contract.

This project was developed as the final assignment for Module 3, focusing on smart contract implementation, adherence to best practices, and code verification.

## Core Features

The `SimpleSwap` contract allows users to perform the following actions for any pair of ERC-20 tokens:

1.  **Add Liquidity (`addLiquidity`)**: Users can deposit a pair of tokens into a liquidity pool. In return, they receive "liquidity provider" (LP) tokens that represent their share of the pool.

2.  **Remove Liquidity (`removeLiquidity`)**: Users can burn their LP tokens to withdraw their proportional share of the underlying tokens from the pool.

3.  **Swap Tokens (`swapExactTokensForTokens`)**: Users can trade one token for another. The exchange rate is determined by the relative quantities of the tokens in the liquidity pool, following a constant product formula.

4.  **Get Price (`getPrice`)**: A view function that returns the current spot price of one token in terms of another, based on the pool's reserves.

5.  **Calculate Swap Amount (`getAmountOut`)**: A pure function that calculates how many output tokens will be received for a given amount of input tokens, which is useful for front-end integration.

## How It Works

-   **Pair Management**: Instead of deploying a new contract for each token pair, `SimpleSwap` manages all liquidity pools internally. It creates a unique `poolId` for each pair by sorting their addresses and hashing them.
-   **State**: The contract stores the token reserves and total liquidity supply for each pool in a `struct`. User liquidity balances are tracked in a separate mapping.
-   **Constant Product Formula**: Swaps are governed by the `x * y = k` formula. A 0.3% fee is applied to trades, which is reinvested into the liquidity pool for the benefit of liquidity providers.

## How to Use

1.  **Deploy**: Deploy the `SimpleSwap.sol` contract to an Ethereum-compatible network.
2.  **Approve Tokens**: Before adding liquidity or swapping, users must approve the `SimpleSwap` contract to spend their ERC-20 tokens by calling the `approve` function on the token contracts.
3.  **Interact**: Call the public functions (`addLiquidity`, `swapExactTokensForTokens`, etc.) on the deployed `SimpleSwap` contract.

## Verification

The contract is designed to be fully compatible with the provided `SwapVerifier.sol` contract. It successfully passes all checks, including adding/removing liquidity, price calculation, and token swapping.
