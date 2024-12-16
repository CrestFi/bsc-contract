// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./interface/IStaking.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "hardhat/console.sol";

contract Staking is
    IStaking,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    // Error messages
    error InvalidTokenAllowance(address token, address sender);
    error InvalidCaller(address sender);
    error InvalidDataSent();

    error InSufficientStakedAmount(
        address token,
        uint256 requestAmount,
        uint256 vaultAmount
    );

    error ValueTooLarge(uint256 maxAmount, uint256 sentAmount);
    error ValueDoNotMatch(uint256 valueOne, uint256 valueTwo);

    error InSufficientAmount(
        address token,
        uint256 requestAmount,
        uint256 balance
    );

    struct WhiteListInformation {
        bool isWhitelisted;
        uint256 streamFee;
    }

    uint256[] private streamFee;
    uint256 private constant MAX_FEE = 100;
    mapping(address => uint256) public noOfTokenStakedByUser;
    uint256 public totalStakedToken;
    uint256[] private stakingTiers;
    mapping(address => mapping(address => WhiteListInformation))
        public whitelistState;
    address public tokenAddress;
    bytes32 private constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

    function initialize(address _tokenAddress) public initializer {
        tokenAddress = _tokenAddress;
        __Ownable_init(_msgSender());
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(WHITELISTER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // Sets the stream fee tiers based on staking tiers
    function setStreamFeeTiers(
        uint256[] calldata _streamFee,
        uint256[] calldata _numberOfTokens
    ) external override onlyRole(WHITELISTER_ROLE) {
        if (_streamFee.length != _numberOfTokens.length)
            revert InvalidDataSent();

        streamFee = _streamFee;
        stakingTiers = _numberOfTokens;

        emit SetStreamFeeTiers(_streamFee, _numberOfTokens);
    }

    // Returns all staking tiers
    function getAllStakingTiers()
        external
        view
        override
        returns (uint256[] memory _stakingTiers)
    {
        _stakingTiers = stakingTiers;
    }

    // Returns all stream fees
    function getAllStreamFee()
        external
        view
        override
        returns (uint256[] memory _streamFee)
    {
        _streamFee = streamFee;
    }

    // Returns the stream fee corresponding to a staking tier
    function getCorrespondingStreamFee(
        uint256 stakingTierIndex
    ) external view override returns (uint256 _streamFee) {
        _streamFee = streamFee[stakingTierIndex];
    }

    // Whitelists wallet addresses for a specific token and sets the stream fee
    function whitelistAddress(
        address _tokenAddress,
        address[] calldata walletAddresses,
        uint256[] calldata _streamFee
    ) external override onlyRole(WHITELISTER_ROLE) {
        uint256 walletAddressesLength = walletAddresses.length;
        uint256 streamFeeLength = _streamFee.length;

        if (walletAddressesLength != streamFeeLength)
            revert ValueDoNotMatch(walletAddressesLength, streamFeeLength);
        if (walletAddressesLength > 600)
            revert ValueTooLarge(600, walletAddressesLength);

        // Iterate over the wallet addresses
        for (uint256 i; i < walletAddressesLength; ) {
            // Set the stream fee and whitelist status for the token and wallet address

            whitelistState[walletAddresses[i]][_tokenAddress]
                .streamFee = _streamFee[i];
            whitelistState[walletAddresses[i]][_tokenAddress]
                .isWhitelisted = true;
            emit WhiteListedAddress(
                _tokenAddress,
                walletAddresses[i],
                _streamFee[i]
            );
            unchecked {
                ++i;
            }
        }
    }

    // Retrieves the stream fee for a given sender and token address
    function getStreamFee(
        address sender,
        address _tokenAddress
    ) external view override returns (uint256 _streamFee) {
        // Checks whether the sender has been whitelisted for the token address
        if (whitelistState[sender][_tokenAddress].isWhitelisted) {
            _streamFee = whitelistState[sender][_tokenAddress].streamFee;
        } else {
            // gets stream fee based on staked tokens
            _streamFee = _getStakingStreamFee(sender);
        }
    }

    // Allows a user to stake tokens
    function stakeTokens(uint256 amount) external override {
        // Check if the user has approved the contract to spend the specified amount of tokens
        if (
            IERC20(tokenAddress).allowance(_msgSender(), address(this)) < amount
        ) revert InvalidTokenAllowance(tokenAddress, _msgSender());

        // Transfer the staked tokens from the user to the contract
        IERC20(tokenAddress).transferFrom(_msgSender(), address(this), amount);

        // Update the staked token balance for the user
        noOfTokenStakedByUser[_msgSender()] =
            noOfTokenStakedByUser[_msgSender()] +
            (amount);

        // Update the total staked token balance
        totalStakedToken = totalStakedToken + (amount);

        // Emit an event to indicate that tokens have been staked
        emit StakedToken(_msgSender(), amount);
    }

    // Allows a user to unstake tokens
    function unstakeTokens(uint256 amount) external override {
        // Check if the user has sufficient staked tokens
        if (noOfTokenStakedByUser[_msgSender()] < amount)
            revert InSufficientStakedAmount(
                tokenAddress,
                amount,
                noOfTokenStakedByUser[_msgSender()]
            );

        // Transfer the unstaked tokens from the contract to the user
        IERC20(tokenAddress).transfer(_msgSender(), amount);

        // Update the staked token balance for the user
        noOfTokenStakedByUser[_msgSender()] =
            noOfTokenStakedByUser[_msgSender()] -
            (amount);

        // Update the total staked token balance
        totalStakedToken = totalStakedToken - (amount);

        // Emit an event to indicate that tokens have been unstaked
        emit UnstakedToken(_msgSender(), amount);
    }

    // Allows the owner to withdraw tokens from the contract collected through stream fee from core contract
    function withdrawTokens(
        address _tokenAddress,
        uint256 amount
    ) external onlyOwner {
        // Checks whether the token address is 0x0,
        if (_tokenAddress != address(0)) {
            // Checks balance of the token address in contract
            if (IERC20(_tokenAddress).balanceOf(address(this)) < amount)
                revert InSufficientAmount(
                    _tokenAddress,
                    amount,
                    IERC20(_tokenAddress).balanceOf(address(this))
                );
            // Transfers amount of the token from contract to owner
            IERC20(_tokenAddress).transfer(owner(), amount);
        } else if (_tokenAddress == tokenAddress) {
            // To differentiate between staked tokens and stream fee balance of stake tokens
            uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(
                address(this)
            );
            // Checks balance of the token address in contract
            if ((tokenBalance - totalStakedToken) < amount)
                revert InSufficientAmount(
                    _tokenAddress,
                    amount,
                    IERC20(_tokenAddress).balanceOf(address(this))
                );
            // Transfers amount of the token from contract to owner
            IERC20(_tokenAddress).transfer(owner(), amount);
        } else {
            // Checks balance of the ETH in contract
            if (address(this).balance < amount)
                revert InSufficientAmount(
                    _tokenAddress,
                    amount,
                    address(this).balance
                );
            // Transfers amount of the ETH contract to owner
            payable(owner()).call{value: amount}("");
        }

        emit TokenWithdrawn(_tokenAddress, owner(), amount);
    }

    // Retrieves the stream fee for a given sender based on their staking amount
    function _getStakingStreamFee(
        address sender
    ) internal view returns (uint256) {
        // Iterates through stream Fee array to determine number of tokens staked by user
        uint256 streamFeeLength = streamFee.length;
        uint256 fee = MAX_FEE;
        for (uint256 i; i < streamFeeLength; ) {
            if (noOfTokenStakedByUser[sender] > stakingTiers[i]) {
                // Returns stream fee corresponding to the staked tokens
                fee = streamFee[i];
                break;
            }
            unchecked {
                ++i;
            }
        }
        // Returns MAX_FEE if not staked any tokens
        return fee;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    // Fallback function to receive Ether
    fallback() external payable {}
    receive() external payable {}
}
