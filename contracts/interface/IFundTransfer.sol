// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IFundTransfer {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     */
    event FundTransfer(
        address indexed from,
        address indexed to,
        address tokenAddress,
        uint256 value
    );

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event FundApproval(
        address indexed owner,
        address indexed spender,
        address tokenAddress,
        uint256 value
    );

    /**
     * @dev returns fundAllowance
     * @param owner    owner of the funds
     * @param spender     spender of the funds
     * @param tokenAddress  address of token
     */
    function fundAllowance(
        address owner,
        address spender,
        address tokenAddress
    ) external view returns (uint256);

    /**
     * @dev approves tokens for a spender from the callers balance
     * @param spender    address of spender
     * @param tokenAddress     address of token
     * @param amount  amount of token to be approved
     */
    function fundApproval(
        address spender,
        address tokenAddress,
        uint256 amount
    ) external;

    /**
     * @dev approves tokens for a spender from the callers balance
     * @param from    owner of token
     * @param to     receiver
     * @param tokenAddress  address of token
     * @param amount  amount of token to be approved
     */
    function fundTransferFrom(
        address from,
        address to,
        address tokenAddress,
        uint256 amount
    ) external;
}