// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.28;

import "../interface/IStaking.sol";

library CoreUtilsLibrary {
    // Calculates the stream fee and the actual withdrawal amount based on the stream fee percent
    function calculateAmount(
        IStaking staking,
        uint256 withdrawAmount,
        address withdrawer,
        address tokenAddress
    ) internal view returns (uint256 streamFee, uint256 actualWithdrawAmount) {
        // Retrieve the stream fee percent for the withdrawer and token address from the staking contract
        uint256 streamFeePercent = staking.getStreamFee(
            withdrawer,
            tokenAddress
        );

        // Calculate the stream fee based on the withdraw amount and the stream fee percent
        streamFee = (withdrawAmount * (streamFeePercent)) / (10000);

        // Calculate the actual withdrawal amount by subtracting the stream fee from the withdraw amount
        actualWithdrawAmount = withdrawAmount - streamFee;
    }

    // Calculates the value of a stream at a given time
    function valueCalculation(
        uint256 currentTime,
        uint256 withdrawTime,
        uint256 endTime,
        uint256 startTime,
        uint256 streamAmount
    ) internal pure returns (uint256 value) {
        // Calculate the value by multiplying the time difference between the withdrawal time and the current time
        // with the stream amount, and dividing it by the time difference between the start time and the end time
        value =
            ((currentTime - withdrawTime) * (streamAmount)) /
            (endTime - startTime);
    }

    // Calculates the allowance bytes32 key for the owner, token address, and spender
    function calculateAllowanceBytes(
        address owner,
        address tokenAddress,
        address spender
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tokenAddress, spender));
    }
}
