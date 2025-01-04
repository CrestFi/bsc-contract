// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "@opengsn/contracts/src/ERC2771Recipient.sol";

import "./interface/ICore.sol";
import "./interface/IStaking.sol";
import "./libs/CoreUtilsLibrary.sol";

import "./interface/IBulkTransfer.sol";
import "./libs/BulkTransferLibrary.sol";
import "./interface/IFundTransfer.sol";
import "./interface/IRegistry.sol";

import "hardhat/console.sol";

contract CrestFiCore is
    ICore,
    IFundTransfer,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    ERC2771Recipient
{
    //Roles
    bytes32 private constant WHITELIST_ROLE = keccak256("WHITELISTER_ROLE");
    bytes32 private constant FUND_WITHDRAW_ROLE =
        keccak256("FUND_WITHDRAW_ROLE");
    bytes32 private constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");

    //Structs
    struct Amount {
        uint256 streamAmount;
        uint256 releasedAmount;
        uint256 unlockedAmount;
        uint256 pausedAmount;
    }

    //Streams

    struct Stream {
        bytes32 name;
        address receiver;
        address token;
        uint256 startTime;
        uint256 endTime;
        Amount amounts;
        uint256 pausedTime;
        uint256 withdrawTime;
        address originCrestFiWallet;
        bool canceled;
        bool paused;
        uint8 streamParam;
        //0 pausable
        //1 cancelable
        //2 pausable & cancelable
        //3 none
    }

    //Wallet
    struct CrestFiWallet {
        uint256 createTime;
        uint256 streamCount;
    }

    //Error Messages
    error StreamNotStarted(uint256 currentTime, uint256 streamStartTime);
    error StreamAlreadyStarted(uint256 currentTime, uint256 streamStartTime);
    error StreamNotEnded(uint256 currentTime, uint256 streamEndTime);
    error StreamAlreadyEnded(uint256 currentTime, uint256 streamEndTime);
    error StreamNotPausable();
    error StreamNotCancelable();
    error StreamNotPaused();
    error StreamPaused();
    error StreamCanceled();

    error SenderCannotBeReceiver();
    error StreamAmountCannotBeZero();
    error InvalidStreamStartTime();
    error InvalidStreamEndTime();

    error InSufficientReleasableAmount(
        address token,
        uint256 requestAmount,
        uint256 availableAmount
    );

    error CrestFiWalletAlreadyExists(bytes32 vault, address caller);
    error CrestFiWalletDoesNotExists(address caller);
    error InvalidZeroAddress();

    error InvalidOwner(address caller, address owner);
    error InvalidSender(address caller, address sender);
    error InvalidReceiver(address caller, address receiver);
    error InvalidWithdrawAmount();
    error InvalidInstantTransferAmount();

    error InvalidToken(address token);
    error InvalidTokenAllowance(address token, address sender);
    error TransferFailed(uint256 amount);

    error BulkTransferStreamAlreadyInitialized();

    error InSufficientCrestFiWalletAmount(
        address token,
        uint256 requestAmount,
        uint256 vaultAmount
    );
    error InvalidTokenData();

    // Modifiers
    modifier isStreamReceiver(bytes32 streamBytes) {
        if (streams[streamBytes].receiver != _msgSender()) {
            revert InvalidReceiver(_msgSender(), streams[streamBytes].receiver);
        }
        _;
    }

    modifier isPausable(bytes32 streamBytes) {
        if (
            (streams[streamBytes].streamParam == 1) ||
            (streams[streamBytes].streamParam == 3) ||
            streams[streamBytes].paused
        ) {
            revert StreamNotPausable();
        }
        _;
    }

    modifier isCancelable(bytes32 streamBytes) {
        if (
            (streams[streamBytes].streamParam == 0) ||
            (streams[streamBytes].streamParam == 3)
        ) {
            revert StreamNotCancelable();
        }
        _;
    }
    modifier isWhitelistedToken(address tokenAddress) {
        if (tokenAddress != address(0) && !whitelistedTokens[tokenAddress]) {
            revert InvalidToken(tokenAddress);
        }
        _;
    }

    //Variables
    mapping(address => CrestFiWallet) public wallets;
    mapping(bytes32 => Stream) public streams;
    mapping(address => mapping(address => uint256)) public walletTokenBalances;
    mapping(bytes32 => uint256) private _fundAllowances;
    mapping(address => bool) public whitelistedTokens;
    mapping(bytes32 => uint256) public bulkTransferWithdrawCount;

    IStaking private staking;
    IBulkTransfer private bulkTransfer;
    IRegistry private tnsRegistry;

    function initialize(
        address _staking,
        address _bulkTransfer,
        address _tnsRegistry
    ) public initializer {
        staking = IStaking(_staking);
        bulkTransfer = IBulkTransfer(_bulkTransfer);
        tnsRegistry = IRegistry(_tnsRegistry);

        __Ownable_init(_msgSender());
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setRoleAdmin(WHITELIST_ROLE, DEFAULT_ADMIN_ROLE);
    }

    function updateBulkTransferContract(
        address bulkTransferContract
    ) external onlyOwner {
        bulkTransfer = IBulkTransfer(bulkTransferContract);
        emit BulkTransferContractUpdated(bulkTransferContract);
    }

    function updateStakingContract(address stakingContract) external onlyOwner {
        staking = IStaking(stakingContract);
        emit StakingContractUpdated(stakingContract);
    }

    function toggleContractPause() external onlyOwner {
        if (paused()) _unpause();
        else _pause();
    }

    // Updates the whitelist status of multiple tokens.
    function updateWhitelistedTokens(
        address[] memory tokens,
        bool[] memory isWhitelisted
    ) external override {
        console.log("hi");
        _checkRole(WHITELIST_ROLE, _msgSender());
        console.log("here");

        uint tokensLength = tokens.length;
        uint isWhitelistedLength = isWhitelisted.length;

        // Check if the length of the token and isWhitelisted arrays match
        if (tokensLength != isWhitelistedLength) revert InvalidTokenData();

        // Update the whitelist status of each token
        for (uint index; index < tokensLength; ) {
            whitelistedTokens[tokens[index]] = isWhitelisted[index];

            // Emit an event for the token whitelist update
            emit TokenWhitelisted(
                tokens[index],
                _msgSender(),
                isWhitelisted[index]
            );
            unchecked {
                ++index;
            }
        }
    }

    //Creates a new Zebec wallet for the given wallet address.
    function _createCrestFiWallet(address walletAddress) internal {
        // Create a new Zebec wallet with the current timestamp as the creation time
        CrestFiWallet memory newWallet = CrestFiWallet({
            createTime: block.timestamp,
            streamCount: 0
        });

        // Store the new Zebec wallet in the wallets mapping
        wallets[walletAddress] = newWallet;

        // Grant the FUND_WITHDRAW_ROLE to the wallet address
        _grantRole(FUND_WITHDRAW_ROLE, walletAddress);

        // Emits Zebec Wallet Creation Event
        emit CreatedCrestFiWallet(walletAddress);
    }

    // Deposits tokens into a Zebec wallet.

    function depositTokens(
        address crestFiWalletAddress,
        uint256 amount,
        address tokenAddress
    ) external payable override whenNotPaused isWhitelistedToken(tokenAddress) {
        // If the Zebec wallet does not exist, create a new one
        if (wallets[crestFiWalletAddress].createTime == 0)
            _createCrestFiWallet(crestFiWalletAddress);

        // Deposit the tokens into the Zebec wallet
        _depositToken(crestFiWalletAddress, amount, tokenAddress);
    }

    // Internal function to deposit tokens into a Zebec wallet.
    function _depositToken(
        address crestFiWalletAddress,
        uint256 amount,
        address tokenAddress
    ) internal {
        // Check if the token to deposit is ETH (address(0))
        if (tokenAddress == address(0)) {
            // Check if the deposited ETH amount matches the provided amount
            if (msg.value != amount) revert TransferFailed(amount);
        } else {
            address owner = crestFiWalletAddress;
            // Check if the sender has approved the contract to spend the specified token amount
            if (IERC20(tokenAddress).allowance(owner, address(this)) < amount)
                revert InvalidTokenAllowance(tokenAddress, _msgSender());

            // Transfer the approved tokens from the wallet owner to the contract
            IERC20(tokenAddress).transferFrom(owner, address(this), amount);
        }

        // Update the token balance in the walletTokenBalances
        walletTokenBalances[crestFiWalletAddress][tokenAddress] =
            walletTokenBalances[crestFiWalletAddress][tokenAddress] +
            (amount);

        // Emit an event for the token deposit
        emit DepositedToken(
            _msgSender(),
            crestFiWalletAddress,
            tokenAddress,
            amount
        );
    }

    // Withdraws tokens from the sender's Zebec wallet to a specified receiver address.
    function withdrawTokens(
        uint256 amount,
        address tokenAddress
    ) external override whenNotPaused {
        // Check if the sender's Zebec wallet exists
        if (wallets[_msgSender()].createTime == 0)
            revert CrestFiWalletDoesNotExists(_msgSender());

        // Check if the withdrawal amount is zero
        if (amount == 0) revert InvalidWithdrawAmount();

        address owner = _msgSender();

        // Check if the sender's Zebec wallet has sufficient token balance for withdrawal
        if (walletTokenBalances[_msgSender()][tokenAddress] < amount)
            revert InSufficientCrestFiWalletAmount(
                tokenAddress,
                amount,
                walletTokenBalances[_msgSender()][tokenAddress]
            );

        // Deduct the token balance of the sender's Zebec wallet
        walletTokenBalances[_msgSender()][tokenAddress] =
            walletTokenBalances[_msgSender()][tokenAddress] -
            (amount);

        // Perform the token withdrawal
        _withdrawToken(_msgSender(), owner, amount, tokenAddress);
    }

    //Internal function that performs the token withdrawal to a specified receiver address.
    function _withdrawToken(
        address walletOwner,
        address receiver,
        uint256 amount,
        address tokenAddress
    ) internal {
        // If the token address is ETH (address(0)), transfer the specified amount as Ether
        if (tokenAddress == address(0)) {
            (bool sent, ) = receiver.call{value: amount}("");
            if (!sent) revert TransferFailed(amount);
        } else {
            // Transfer the specified amount of tokens to the receiver address
            IERC20(tokenAddress).transfer(receiver, amount);
        }

        // Emit an event for the token withdrawal
        emit WalletWithdrawn(receiver, walletOwner, tokenAddress, amount);
    }

    // Internal function that performs the token withdrawal to the receiver's Zebec wallet.
    function _withdrawTokenInCrestFiWallet(
        address walletOwner,
        address receiver,
        uint256 amount,
        address tokenAddress
    ) internal {
        // Increase the token balance of the receiver's Zebec wallet
        walletTokenBalances[receiver][tokenAddress] =
            walletTokenBalances[receiver][tokenAddress] +
            (amount);

        // Emit an event for the token withdrawal to the Zebec wallet
        emit CrestFiWalletWithdrawn(receiver, walletOwner, tokenAddress, amount);
    }

    function instantTokenTransferTNS(
        bytes32 name,
        address token,
        uint256 tokenAmount,
        string memory receiverLabel,
        bool crestFiWalletWithdraw
    ) external payable override isWhitelistedToken(token) {
        uint256 receiverId = subTokenId(tnsRegistry.root(), receiverLabel);

        instantTokenTransfer(
            name,
            token,
            tokenAmount,
            tnsRegistry.ownerOf(receiverId),
            crestFiWalletWithdraw
        );
    }

    function instantTokenTransfer(
        bytes32 name,
        address token,
        uint256 tokenAmount,
        address receiver,
        bool crestFiWalletWithdraw
    ) public override whenNotPaused isWhitelistedToken(token) {
        // Check for valid receiver address
        if (receiver == address(0)) revert InvalidZeroAddress();

        // Check if the token amount is zero
        if (tokenAmount == 0) revert InvalidInstantTransferAmount();

        // Check if the sender's Zebec wallet exists
        if (wallets[_msgSender()].createTime == 0)
            revert CrestFiWalletDoesNotExists(_msgSender());

        // Perform the instant token transfer
        _instantTransfer(
            name,
            token,
            tokenAmount,
            _msgSender(),
            receiver,
            crestFiWalletWithdraw
        );
    }

    // Internal function that performs the actual instant token transfer from the sender's Zebec wallet to the receiver.

    function _instantTransfer(
        bytes32 name,
        address token,
        uint256 tokenAmount,
        address sender,
        address receiver,
        bool crestFiWalletWithdraw
    ) internal {
        // Check if the sender's Zebec wallet has sufficient token balance
        uint256 availableAmount = walletTokenBalances[sender][token];
        if (availableAmount < tokenAmount)
            revert InSufficientCrestFiWalletAmount(
                token,
                tokenAmount,
                availableAmount
            );

        // Deduct the transferred tokens from the sender's Zebec wallet
        walletTokenBalances[sender][token] =
            walletTokenBalances[sender][token] -
            (tokenAmount);

        // Perform the token withdrawal either in the Zebec wallet or directly to the receiver

        if (crestFiWalletWithdraw)
            _withdrawTokenInCrestFiWallet(sender, receiver, tokenAmount, token);
        else _withdrawToken(sender, receiver, tokenAmount, token);

        // Emit an event for the instant token transfer
        emit InstantTokenTransfer(name, sender, token, tokenAmount, receiver);
    }

    function createStreamTNS(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        string memory streamReceiverLabel,
        uint256 streamStartTime,
        uint256 streamEndTime,
        bool streamCancelable,
        bool streamPausable
    ) external override isWhitelistedToken(streamingToken) {
        uint256 streamReceiverId = subTokenId(
            tnsRegistry.root(),
            streamReceiverLabel
        );

        createStream(
            streamName,
            streamingAmount,
            streamingToken,
            tnsRegistry.ownerOf(streamReceiverId),
            streamStartTime,
            streamEndTime,
            streamCancelable,
            streamPausable
        );
    }

    // Creates a stream for transferring tokens from the sender's Zebec wallet to a receiver's address.

    function createStream(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        address streamReceiver,
        uint256 streamStartTime,
        uint256 streamEndTime,
        bool streamCancelable,
        bool streamPausable
    ) public override whenNotPaused isWhitelistedToken(streamingToken) {
        // Check if the sender and receiver addresses are different
        if (_msgSender() == streamReceiver) revert SenderCannotBeReceiver();

        // Check if the stream receiver address is valid
        if (streamReceiver == address(0)) revert InvalidZeroAddress();

        // Check if the sender address is valid
        if (_msgSender() == address(0)) revert InvalidZeroAddress();

        // Check if the streaming amount is greater than zero
        if (streamingAmount == 0) revert StreamAmountCannotBeZero();

        // Check if the stream start time is valid
        if (streamStartTime <= block.timestamp) revert InvalidStreamStartTime();

        // Check if the stream end time is valid
        if (streamEndTime <= block.timestamp) revert InvalidStreamEndTime();

        // If the sender's Zebec wallet does not exist, create a new one
        if (wallets[_msgSender()].createTime == 0)
            _createCrestFiWallet(_msgSender());

        // Create the stream parameter
        uint8 streamParam = _createStreamParam(
            streamCancelable,
            streamPausable
        );

        // Call the internal function to create the stream
        _createStream(
            streamName,
            streamingAmount,
            streamingToken,
            _msgSender(),
            streamReceiver,
            streamStartTime,
            streamEndTime,
            streamParam
        );
    }

    function _createStreamParam(
        bool cancelable,
        bool pausable
    ) internal pure returns (uint8 streamParam) {
        if (pausable && cancelable) {
            streamParam = 2;
        } else if (pausable) {
            streamParam = 0;
        } else if (cancelable) {
            streamParam = 1;
        } else {
            streamParam = 3;
        }
    }

    function instantStreamTNS(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        string memory streamReceiverLabel,
        uint256 streamStartTime,
        uint256 streamEndTime,
        bool streamCancelable,
        bool streamPausable
    ) external payable isWhitelistedToken(streamingToken) {
        uint256 streamReceiverId = subTokenId(
            tnsRegistry.root(),
            streamReceiverLabel
        );

        instantStream(
            streamName,
            streamingAmount,
            streamingToken,
            tnsRegistry.ownerOf(streamReceiverId),
            streamStartTime,
            streamEndTime,
            streamCancelable,
            streamPausable
        );
    }

    //  Creates an instant stream with the specified parameters.

    function instantStream(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        address streamReceiver,
        uint256 streamStartTime,
        uint256 streamEndTime,
        bool streamCancelable,
        bool streamPausable
    )
        public
        payable
        override
        nonReentrant
        whenNotPaused
        isWhitelistedToken(streamingToken)
    {
        // Check if the sender is the same as the receiver
        if (_msgSender() == streamReceiver) revert SenderCannotBeReceiver();

        // Check for valid addresses
        if (streamReceiver == address(0)) revert InvalidZeroAddress();
        if (_msgSender() == address(0)) revert InvalidZeroAddress();

        // Check if the streaming amount is zero
        if (streamingAmount == 0) revert StreamAmountCannotBeZero();

        // Check if the stream start time is valid
        if (streamStartTime <= block.timestamp) revert InvalidStreamStartTime();

        // Check if the stream end time is valid
        if (streamEndTime <= block.timestamp) revert InvalidStreamEndTime();

        // Create a Zebec wallet for the sender if it doesn't exist
        if (wallets[_msgSender()].createTime == 0)
            _createCrestFiWallet(_msgSender());

        // Deposit the streaming amount of tokens from the sender's wallet
        _depositToken(_msgSender(), streamingAmount, streamingToken);

        // Generate a stream address
        bytes32 streamAddress = calculateStreamBytes(
            _msgSender(),
            wallets[_msgSender()].streamCount
        );

        // Create the stream with the provided parameters
        uint8 streamParam = _createStreamParam(
            streamCancelable,
            streamPausable
        );
        _createStream(
            streamName,
            streamingAmount,
            streamingToken,
            _msgSender(),
            streamReceiver,
            streamStartTime,
            streamEndTime,
            streamParam
        );

        // Emit an event indicating the successful creation of the Zebec wallet and stream
        emit CreatedCrestFiWalletAndStreamed(
            _msgSender(),
            streamAddress,
            streamingToken,
            streamingAmount,
            streamReceiver
        );
    }

    //Internal function to create a stream with the specified parameters.

    function _createStream(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        address streamSender,
        address streamReceiver,
        uint256 streamStartTime,
        uint256 streamEndTime,
        uint8 streamParam
    ) internal returns (bytes32 streamAddress) {
        // Retrieve the sender's Zebec wallet
        CrestFiWallet storage senderWallet = wallets[streamSender];

        // Calculate the stream address
        streamAddress = calculateStreamBytes(
            streamSender,
            wallets[streamSender].streamCount
        );

        // Create an Amount struct to store stream-related amounts
        Amount memory amount = Amount({
            streamAmount: streamingAmount,
            releasedAmount: 0,
            unlockedAmount: 0,
            pausedAmount: 0
        });

        uint256 _streamingAmount = streamingAmount;

        // Create a Stream struct to store the stream details
        Stream memory currentStream = Stream({
            name: streamName,
            receiver: streamReceiver,
            token: streamingToken,
            startTime: streamStartTime,
            endTime: streamEndTime,
            amounts: amount,
            pausedTime: 0,
            withdrawTime: streamStartTime,
            originCrestFiWallet: streamSender,
            canceled: false,
            paused: false,
            streamParam: streamParam
        });

        // Store the stream in the streams mapping using the generated address as the key
        streams[streamAddress] = currentStream;

        // Increment the stream count of the sender's Zebec wallet
        senderWallet.streamCount = senderWallet.streamCount + (1);

        // Emit an event indicating the successful creation of the stream
        emit CreatedStream(
            streamName,
            streamSender,
            streamReceiver,
            streamingToken,
            streamStartTime,
            streamEndTime,
            _streamingAmount,
            streamAddress,
            streamParam
        );
    }

    function withdrawStream(
        bytes32 streamBytes,
        uint256 withdrawAmount,
        bool crestFiWalletWithdraw
    ) public override whenNotPaused isStreamReceiver(streamBytes) {
        // Ensure the withdrawal amount is valid
        if (withdrawAmount == 0) revert InvalidWithdrawAmount();

        // Retrieve the stream information from storage
        Stream storage currentStream = streams[streamBytes];
        uint256 startTime = currentStream.startTime;
        uint256 pausedTime = currentStream.pausedTime;
        uint256 streamAmount = currentStream.amounts.streamAmount;
        bool paused = currentStream.paused;
        address originCrestFiWallet = currentStream.originCrestFiWallet;
        address token = currentStream.token;
        address receiver = currentStream.receiver;

        // Check if the stream has started
        if (startTime > block.timestamp)
            revert StreamNotStarted(block.timestamp, startTime);

        // Check if the caller is the receiver of the stream
        if (_msgSender() != receiver)
            revert InvalidReceiver(_msgSender(), receiver);

        // Check if the stream has been canceled
        if (currentStream.canceled) revert StreamCanceled();

        // Calculate the releasable amount for the stream
        uint256 releasableAmount = calculateReleasableAmount(streamBytes);

        // Check if the withdrawal amount exceeds the releasable and unlocked amounts
        if (releasableAmount < withdrawAmount)
            revert InSufficientReleasableAmount(
                token,
                withdrawAmount,
                streamAmount
            );

        // Check if the withdrawal amount exceeds the balance in the Zebec wallet
        if (withdrawAmount > walletTokenBalances[originCrestFiWallet][token])
            revert InSufficientCrestFiWalletAmount(
                token,
                releasableAmount,
                walletTokenBalances[originCrestFiWallet][token]
            );

        // Set the withdrawal time based on the stream state (paused or active)
        if (paused) {
            currentStream.withdrawTime = pausedTime;
        } else {
            currentStream.withdrawTime = block.timestamp;
        }

        // Update the released and unlocked amounts for the stream
        currentStream.amounts.releasedAmount =
            currentStream.amounts.releasedAmount +
            (withdrawAmount);

        if (
            currentStream.amounts.releasedAmount <
            currentStream.amounts.streamAmount
        ) {
            currentStream.amounts.unlockedAmount =
                releasableAmount -
                withdrawAmount;
        } else {
            currentStream.amounts.unlockedAmount = 0;
        }

        // Calculate the stream fee and the actual withdrawal amount
        (uint256 streamFee, uint256 actualWithdrawAmount) = CoreUtilsLibrary
            .calculateAmount(staking, withdrawAmount, _msgSender(), token);

        // Deduct the withdrawal amount from the balance in the Zebec wallet
        walletTokenBalances[originCrestFiWallet][token] =
            walletTokenBalances[originCrestFiWallet][token] -
            (withdrawAmount);

        // uint256 _withdrawAmount = withdrawAmount;

        // Perform the token withdrawal from the staking contract
        _withdrawToken(originCrestFiWallet, address(staking), streamFee, token);

        // Perform the token withdrawal either in the Zebec wallet or directly to the receiver
        if (crestFiWalletWithdraw)
            _withdrawTokenInCrestFiWallet(
                originCrestFiWallet,
                receiver,
                actualWithdrawAmount,
                token
            );
        else
            _withdrawToken(
                originCrestFiWallet,
                receiver,
                actualWithdrawAmount,
                token
            );

        // Emit an event indicating the successful stream withdrawal
        emit WithdrawnStream(
            streamBytes,
            originCrestFiWallet,
            receiver,
            currentStream.amounts.releasedAmount
        );
    }

    function withdrawBulkInstantTransfer(
        uint256 bulkTransferIndex,
        uint256 transferingAmount,
        address transferingToken,
        address transferSender,
        address transferReceiver,
        bytes32[] memory proofs,
        bool crestFiWalletWithdraw
    ) external override whenNotPaused {
        // Generate the bulk transfer address using the data
        bytes32 bulkTransferAddress = keccak256(
            abi.encodePacked(
                bulkTransferIndex,
                transferingAmount,
                transferingToken,
                transferSender,
                transferReceiver
            )
        );

        uint256 recurringFrequency = bulkTransfer
            .getBulkTransferRecurringFrequency(
                transferSender,
                bulkTransferIndex
            );

        uint256 releasedRecurringFrequency = bulkTransfer
            .getBestRecurringFrequencyBasedOnStartTime(
                transferSender,
                bulkTransferIndex
            );

        uint256 difference = releasedRecurringFrequency -
            bulkTransferWithdrawCount[bulkTransferAddress];

        if (
            bulkTransferWithdrawCount[bulkTransferAddress] + difference >
            recurringFrequency
        ) revert BulkTransferStreamAlreadyInitialized();
        if (difference <= 0)
            revert BulkTransferLibrary.BulkTransferNotStarted();
        bulkTransferWithdrawCount[
            bulkTransferAddress
        ] = releasedRecurringFrequency;

        // Perform verification of the bulk transfer
        bytes32 streamName = BulkTransferLibrary
            .instantBulkTransferVerification(
                bulkTransfer,
                bulkTransferIndex,
                transferingAmount,
                transferingToken,
                transferSender,
                transferReceiver,
                releasedRecurringFrequency,
                proofs
            );

        // Perform the instant transfer of funds
        _instantTransfer(
            streamName,
            transferingToken,
            transferingAmount * difference,
            transferSender,
            transferReceiver,
            crestFiWalletWithdraw
        );
        emit BulkTransferInstantTransfer(
            bulkTransferIndex,
            transferReceiver,
            transferSender,
            bulkTransferWithdrawCount[bulkTransferAddress]
        );
    }

    function withdrawBulkTransferStream(
        uint256 bulkTransferIndex,
        uint256 transferingAmount,
        address transferingToken,
        address transferSender,
        address transferReceiver,
        uint256 transferStartTime,
        uint256 transferEndTime,
        uint8 streamParam,
        bytes32[] memory proofs,
        uint256 withdrawAmount,
        bool crestFiWalletWithdraw
    ) external override whenNotPaused {
        // Generate the bulk transfer address using the data
        bytes32 bulkTransferAddress = keccak256(
            abi.encodePacked(
                bulkTransferIndex,
                transferingAmount,
                transferingToken,
                transferSender,
                transferReceiver,
                transferStartTime,
                transferEndTime,
                streamParam
            )
        );

        // Check if the bulk transfer stream has already been initialized

        uint256 recurringFrequency = bulkTransfer
            .getBulkTransferRecurringFrequency(
                transferSender,
                bulkTransferIndex
            );

        if (
            bulkTransferWithdrawCount[bulkTransferAddress] + 1 >
            recurringFrequency
        ) revert BulkTransferStreamAlreadyInitialized();
        bulkTransferWithdrawCount[bulkTransferAddress] =
            bulkTransferWithdrawCount[bulkTransferAddress] +
            1;
        // Perform verification of the bulk transfer stream
        bytes32 streamName = BulkTransferLibrary.bulkStreamVerification(
            bulkTransfer,
            bulkTransferIndex,
            transferingAmount,
            transferingToken,
            transferSender,
            transferReceiver,
            transferStartTime,
            transferEndTime,
            bulkTransferWithdrawCount[bulkTransferAddress],
            streamParam,
            proofs
        );

        // Create the stream and perform a withdrawal
        bytes32 streamAddress = _createStream(
            streamName,
            transferingAmount,
            transferingToken,
            transferSender,
            transferReceiver,
            transferStartTime,
            transferEndTime,
            streamParam
        );

        withdrawStream(streamAddress, withdrawAmount, crestFiWalletWithdraw);

        // Emit an event indicating the successful bulk transfer stream
        emit BulkTransferStreamed(
            transferReceiver,
            transferSender,
            bulkTransferIndex,
            recurringFrequency
        );
    }

    // Returns total released amount by adding released amount with unlocked amount
    function calculateReleasableAmount(
        bytes32 streamBytes
    ) public view override returns (uint256 releaseAmount) {
        Stream memory stream = streams[streamBytes];
        uint256 releasableAmount = _calculateReleasableAmount(streamBytes);

        releaseAmount =
            releaseAmount +
            (releasableAmount) +
            (stream.amounts.unlockedAmount);
    }

    //Calculates the amount that can be released from a stream based on its current state and time.

    function _calculateReleasableAmount(
        bytes32 streamBytes
    ) internal view returns (uint256 releaseAmount) {
        // Retrieve the stream and its relevant parameters
        Stream memory currentStream = streams[streamBytes];
        uint256 startTime = currentStream.startTime;
        uint256 endTime = currentStream.endTime;
        uint256 withdrawTime = currentStream.withdrawTime;
        uint256 pausedTime = currentStream.pausedTime;
        uint256 streamAmount = currentStream.amounts.streamAmount;
        bool paused = currentStream.paused;

        // Determine the releasable amount based on the stream state and time
        if (startTime >= block.timestamp) {
            releaseAmount = 0; // Stream has not started yet
        } else if (endTime <= block.timestamp) {
            // Stream has already ended
            if (paused) {
                releaseAmount = CoreUtilsLibrary.valueCalculation(
                    pausedTime,
                    withdrawTime,
                    endTime,
                    startTime,
                    streamAmount
                );
            } else {
                releaseAmount =
                    streamAmount -
                    (currentStream.amounts.releasedAmount) -
                    (currentStream.amounts.pausedAmount) -
                    (currentStream.amounts.unlockedAmount);
            }
        } else {
            // Stream is ongoing
            if (paused) {
                releaseAmount = CoreUtilsLibrary.valueCalculation(
                    pausedTime,
                    withdrawTime,
                    endTime,
                    startTime,
                    streamAmount
                );
            } else {
                releaseAmount = CoreUtilsLibrary.valueCalculation(
                    block.timestamp,
                    withdrawTime,
                    endTime,
                    startTime,
                    streamAmount
                );
            }
        }
    }

    function cancelStream(
        bytes32 streamBytes
    ) external override whenNotPaused isCancelable(streamBytes) {
        // Get the stream details from the storage
        Stream storage stream = streams[streamBytes];
        uint256 endTime = stream.endTime;
        address token = stream.token;
        address originCrestFiWallet = stream.originCrestFiWallet;

        // Check if the stream has already ended
        if (block.timestamp >= endTime)
            revert StreamAlreadyEnded(block.timestamp, endTime);

        // Mark the stream as canceled
        stream.canceled = true;

        // Calculate the releasable amount and update the released amount and withdraw time
        uint256 releasableAmount = calculateReleasableAmount(streamBytes);
        stream.amounts.releasedAmount =
            stream.amounts.releasedAmount +
            (releasableAmount);
        stream.withdrawTime = endTime;

        // Check if the crest wallet has sufficient balance to cover the releasable amount
        if (releasableAmount >= walletTokenBalances[originCrestFiWallet][token])
            revert InSufficientCrestFiWalletAmount(
                token,
                releasableAmount,
                walletTokenBalances[originCrestFiWallet][token]
            );

        // Update the crest wallet balance by subtracting the released amount
        walletTokenBalances[originCrestFiWallet][token] =
            walletTokenBalances[originCrestFiWallet][token] -
            (releasableAmount);

        // Calculate the stream fee and actual withdraw amount using the CoreUtilsLibrary
        (uint256 streamFee, uint256 actualWithdrawAmount) = CoreUtilsLibrary
            .calculateAmount(staking, releasableAmount, _msgSender(), token);

        // Withdraw the stream fee from the crest wallet to the staking contract
        _withdrawToken(originCrestFiWallet, address(staking), streamFee, token);

        // Withdraw the actual withdraw amount from the crest wallet to the stream receiver
        _withdrawToken(
            originCrestFiWallet,
            stream.receiver,
            actualWithdrawAmount,
            token
        );

        // Emit the StoppedStreaming event
        emit StoppedStreaming(
            streamBytes,
            originCrestFiWallet,
            stream.amounts.releasedAmount
        );
    }

    // Pauses a stream

    function pauseStream(
        bytes32 streamBytes
    ) external whenNotPaused isPausable(streamBytes) {
        // Retrieve the stream and perform various validations
        Stream storage stream = streams[streamBytes];
        if (stream.originCrestFiWallet != _msgSender())
            revert InvalidOwner(_msgSender(), stream.originCrestFiWallet);
        if (block.timestamp < stream.startTime)
            revert StreamNotStarted(block.timestamp, stream.startTime);
        if (block.timestamp >= stream.endTime)
            revert StreamAlreadyEnded(block.timestamp, stream.endTime);

        // Set the stream as paused and record the paused time
        stream.paused = true;
        stream.pausedTime = block.timestamp;

        // Calculate the releasable amount for the stream
        uint256 releasableAmount = calculateReleasableAmount(streamBytes);

        // Emit the PausedStreaming event
        emit PausedStreaming(streamBytes, stream.pausedTime, releasableAmount);
    }

    // Resumes a paused stream
    function resumeStream(bytes32 streamBytes) external override whenNotPaused {
        // Retrieve the stream and its relevant parameters
        Stream storage stream = streams[streamBytes];
        uint256 startTime = stream.startTime;
        uint256 endTime = stream.endTime;
        uint256 withdrawTime = stream.withdrawTime;
        uint256 pausedTime = stream.pausedTime;
        uint256 streamAmount = stream.amounts.streamAmount;

        // Perform validations for resuming the stream
        if (block.timestamp < startTime)
            revert StreamNotStarted(block.timestamp, startTime);
        if (block.timestamp >= endTime)
            revert StreamAlreadyEnded(block.timestamp, endTime);
        if (!stream.paused) revert StreamNotPaused();

        // Set the stream as not paused
        stream.paused = false;

        // Update the withdraw time and calculate the additional paused amount
        stream.withdrawTime = withdrawTime + (block.timestamp - (pausedTime));
        uint256 pausedAmount = CoreUtilsLibrary.valueCalculation(
            block.timestamp,
            pausedTime,
            endTime,
            startTime,
            streamAmount
        );
        stream.amounts.pausedAmount =
            stream.amounts.pausedAmount +
            (pausedAmount);

        // Clear the paused time
        stream.pausedTime = 0;

        // Emit the ResumedStreaming event
        emit ResumedStreaming(streamBytes, stream.amounts.pausedAmount);
    }

    // Updates the parameters of a stream before the startTime

    function updateStream(
        bytes32 streamBytes,
        bytes32 streamName,
        uint256 streamStartTime,
        uint256 streamEndTime,
        uint256 streamAmount
    ) external override whenNotPaused {
        // Retrieve the current stream and perform validations
        Stream storage currentStream = streams[streamBytes];
        if (currentStream.originCrestFiWallet != _msgSender())
            revert InvalidOwner(_msgSender(), currentStream.originCrestFiWallet);
        if (block.timestamp >= currentStream.startTime)
            revert StreamAlreadyStarted(
                block.timestamp,
                currentStream.startTime
            );
        if (currentStream.canceled) revert StreamCanceled();

        // Update the stream parameters
        currentStream.startTime = streamStartTime;
        currentStream.name = streamName;
        currentStream.withdrawTime = streamStartTime;
        currentStream.endTime = streamEndTime;
        currentStream.amounts.streamAmount = streamAmount;

        // Emit the UpdatedStream event
        emit UpdatedStream(
            streamBytes,
            streamName,
            currentStream.originCrestFiWallet,
            streamStartTime,
            streamEndTime,
            streamAmount
        );
    }

    // Retrieves the token balances of a Zebec wallet for multiple token addresses.

    function getCrestFiWalletTokenBalance(
        address[] calldata sender,
        address[] calldata tokenAddresses
    ) external view returns (uint256[] memory) {
        uint256 senderLength = sender.length;
        uint256 tokenAddressesLength = tokenAddresses.length;

        uint256[] memory tokenBalances = new uint256[](
            tokenAddressesLength * senderLength
        );
        for (uint i; i < senderLength; ) {
            for (uint256 j; j < tokenAddressesLength; ) {
                uint addrIdx = j + tokenAddressesLength * i;

                tokenBalances[addrIdx] = walletTokenBalances[sender[i]][
                    tokenAddresses[j]
                ];
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return tokenBalances;
    }

    //Retrieves the token balances of a wallet for multiple token addresses.

    function getWalletTokenBalance(
        address[] calldata sender,
        address[] calldata tokenAddresses
    ) external view returns (uint256[] memory) {
        uint256 senderLength = sender.length;
        uint256 tokenAddressesLength = tokenAddresses.length;
        uint256[] memory tokenBalances = new uint256[](
            tokenAddresses.length * sender.length
        );
        for (uint i; i < senderLength; ) {
            for (uint256 j; j < tokenAddressesLength; ) {
                uint addrIdx = j + tokenAddressesLength * i;

                if (tokenAddresses[j] != address(0)) {
                    tokenBalances[addrIdx] = IERC20(tokenAddresses[j])
                        .balanceOf(sender[i]);
                } else {
                    tokenBalances[addrIdx] = sender[i].balance;
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }
        return tokenBalances;
    }

    // Grants approval to spend tokens from the Zebec wallet for a spender.

    function fundApproval(
        address spender,
        address tokenAddress,
        uint256 amount
    ) external override onlyRole(FUND_WITHDRAW_ROLE) {
        // Check if the spender address is not zero
        if (spender == address(0)) revert InvalidZeroAddress();

        // Check if the Zebec wallet exists
        if (wallets[_msgSender()].createTime == 0)
            revert CrestFiWalletDoesNotExists(_msgSender());

        // Check if the Zebec wallet has sufficient balance of the token
        if (walletTokenBalances[_msgSender()][tokenAddress] < amount)
            revert InSufficientCrestFiWalletAmount(
                tokenAddress,
                amount,
                walletTokenBalances[_msgSender()][tokenAddress]
            );

        // Calculate the unique allowance byte
        bytes32 allowanceByte = CoreUtilsLibrary.calculateAllowanceBytes(
            _msgSender(),
            tokenAddress,
            spender
        );

        // Set the allowance amount
        _fundAllowances[allowanceByte] = amount;

        // Emit the FundApproval event
        emit FundApproval(_msgSender(), spender, tokenAddress, amount);
    }

    // Retrieves the allowance amount for a specific owner, spender, and token.

    function fundAllowance(
        address owner,
        address spender,
        address tokenAddress
    ) external view override returns (uint256) {
        // Calculate the unique allowance byte
        bytes32 allowanceByte = CoreUtilsLibrary.calculateAllowanceBytes(
            owner,
            tokenAddress,
            spender
        );

        // Retrieve and return the allowance amount
        return _fundAllowances[allowanceByte];
    }

    // Transfers tokens from one address to another using the approved allowance.
    function fundTransferFrom(
        address from,
        address to,
        address tokenAddress,
        uint256 amount
    ) external override {
        // Check if the 'from' address is not zero
        if (from == address(0)) revert InvalidZeroAddress();

        // Check if the 'to' address is not zero
        if (to == address(0)) revert InvalidZeroAddress();

        // Calculate the unique allowance byte
        bytes32 allowanceByte = CoreUtilsLibrary.calculateAllowanceBytes(
            from,
            tokenAddress,
            _msgSender()
        );

        // Retrieve the current allowance amount
        uint256 currentAllowance = _fundAllowances[allowanceByte];

        // Check if the current allowance is sufficient for the transfer
        if (currentAllowance < amount)
            revert InvalidTokenAllowance(tokenAddress, _msgSender());

        // Check if the 'from' address has sufficient balance of the token
        uint256 fromBalance = walletTokenBalances[from][tokenAddress];
        if (fromBalance < amount)
            revert InSufficientCrestFiWalletAmount(
                tokenAddress,
                amount,
                fromBalance
            );

        // Update the token balances and allowance after the transfer
        walletTokenBalances[from][tokenAddress] =
            walletTokenBalances[from][tokenAddress] -
            (amount);
        _fundAllowances[allowanceByte] =
            _fundAllowances[allowanceByte] -
            (amount);

        // Perform the actual token transfer
        _withdrawToken(from, to, amount, tokenAddress);

        // Emit the FundTransfer event
        emit FundTransfer(from, to, tokenAddress, amount);
    }

    //Calculates the unique stream bytes using the Zebec wallet address and stream count.

    function calculateStreamBytes(
        address crestFiWallet,
        uint256 _streamCount
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(crestFiWallet, _streamCount));
    }

    // calculates Minimum Deposit amount in wallet and total outgoing balance of the sender for the array of token Addresses provided
    function calculateMinimumDepositAmount(
        address crestFiWallet,
        address[] calldata tokenAddress
    )
        external
        view
        returns (
            uint256[] memory minimumDeposit,
            uint256[] memory outgoingStreamBalance
        )
    {
        uint256 tokenAddressLength = tokenAddress.length;
        // Initialize arrays to store minimum deposit and balance required
        minimumDeposit = new uint256[](tokenAddressLength);
        outgoingStreamBalance = new uint256[](tokenAddressLength);

        // Iterate over the streams in the Zebec wallet
        for (uint256 i; i < wallets[crestFiWallet].streamCount; ++i) {
            // Iterate over the token addresses
            for (uint256 j; j < tokenAddressLength; ++j) {
                // Calculate the unique stream bytes
                bytes32 streamBytes = calculateStreamBytes(crestFiWallet, i);

                // Check if the stream's token matches the current token address
                if (streams[streamBytes].token == tokenAddress[j]) {
                    // Calculate the balance required for the token by subtracting the released amount from the stream amount
                    outgoingStreamBalance[j] =
                        outgoingStreamBalance[j] +
                        ((streams[streamBytes].amounts.streamAmount) -
                            (streams[streamBytes].amounts.releasedAmount));
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        // Calculate the minimum deposit for each token based on the wallet's token balances
        for (uint256 j; j < tokenAddressLength; ) {
            if (
                outgoingStreamBalance[j] <=
                walletTokenBalances[crestFiWallet][tokenAddress[j]]
            ) {
                // If the balance required is less than or equal to the wallet's token balance, minimum deposit is set to 0
                minimumDeposit[j] = 0;
            } else {
                // Otherwise, calculate the minimum deposit by subtracting the wallet's token balance from the outgoing stream balance
                minimumDeposit[j] =
                    outgoingStreamBalance[j] -
                    (walletTokenBalances[crestFiWallet][tokenAddress[j]]);
            }
            unchecked {
                ++j;
            }
        }
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    fallback() external payable {}

    receive() external payable {}

    function grantWhitelisterRole(address user) external onlyOwner {
        grantRole(WHITELIST_ROLE, user);
    }

    /// @inheritdoc IERC2771Recipient
    function _msgSender()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771Recipient)
        returns (address ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /// @inheritdoc IERC2771Recipient
    function _msgData()
        internal
        view
        virtual
        override(ContextUpgradeable, ERC2771Recipient)
        returns (bytes calldata ret)
    {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    //tns
    function subTokenId(
        uint256 tokenId,
        string memory label
    ) public pure returns (uint256) {
        require(bytes(label).length != 0, "Label is Empty");
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        keccak256(abi.encodePacked(label))
                    )
                )
            );
    }
}