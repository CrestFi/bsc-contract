// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IStaking {
    // @dev This emits when the tokens are staked by the user
    event StakedToken(address indexed staker, uint256 amount);

    // @dev This emits when the tokens are untsaked by the user
    event UnstakedToken(address indexed staker, uint256 amount);

    // @dev This emits when the streamFee is updated
    event StreamFeeUpdated(uint256 newStreamFee);

    // @dev This emits when the collected streamFee are withdrawn
    event TokenWithdrawn(
        address tokenAddress,
        address withdrawer,
        uint256 amount
    );

    // @dev This emits when the streamFee is updated
    event SetStreamFeeTiers(uint256[] streamFee, uint256[] numberOfTokens);

    // @dev This emits when the whitelist Address  is updated
    event WhiteListedAddress(address tokenAddress, address walletAddress, uint256 streamFee);

    /**
        @dev gets stream fee percent based on users
        @param sender Withdrawer of stream

    */
    function getStreamFee(
        address sender,
        address tokenAddress
    ) external view returns (uint256);

    /**
        @dev stakes tokens
        @param amount  amount of the tokens to be staked

    */

    function stakeTokens(uint256 amount) external;

    /**
        @dev unstakes tokens
        @param amount  amount of the tokens to be unstaked

    */

    function unstakeTokens(uint256 amount) external;

    /**
        @dev sets new base stream fee
        @param _streamFee  new stream fee
        @param numberOfTokens  new stream fee
    */

    function setStreamFeeTiers(
        uint256[] calldata _streamFee,
        uint256[] calldata numberOfTokens
    ) external;

    /**
        @dev returns all the values in staking tier array
    */

    function getAllStakingTiers()
        external
        view
        returns (uint256[] memory _stakingTiers);

    /**
        @dev returns all the values in stream fee array
    */

    function getAllStreamFee()
        external
        view
        returns (uint256[] memory _streamFee);

    /**
        @dev returns streamFee based on the index of staking tier value
    */

    function getCorrespondingStreamFee(
        uint256 stakingTierIndex
    ) external view returns (uint256 _streamFee);

    /**
        @dev whitelists addresses and sets their streamFee
        @param _tokenAddress  new stream fee
        @param walletAddresses  new stream fee
        @param _streamFee  new stream fee
    */

    function whitelistAddress(
        address _tokenAddress,
        address[] calldata walletAddresses,
        uint256[] calldata _streamFee
    ) external;
}
