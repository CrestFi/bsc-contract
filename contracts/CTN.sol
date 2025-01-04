/**
 *Submitted for verification at Etherscan.io on 2022-03-28
 */

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/math/SafeCast.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @custom:security-contact ultibets@protonmail.com
contract CTN is ERC20 {
    constructor()
        ERC20("CrestFi Token", "CTN")
    {
        _mint(msg.sender, 1000000000 * 10 ** 18);
    }
}
