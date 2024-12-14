// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface ICore {
    // @dev This emits when the vault is created
    event CreatedCrestWallet(address indexed owner);

    // @dev This emits when the tokens are desposited to the crest wallet
    event DepositedToken(
        address indexed sender,
        address crestWallet,
        address tokenAddress,
        uint256 amount
    );

    // @dev This emits when the funds are withdrawn to the wallet
    event WalletWithdrawn(
        address indexed receiver,
        address owner,
        address tokenAddress,
        uint256 amount
    );

    // @dev This emits when the funds are withdrawn to the crest wallet
    event CrestWalletWithdrawn(
        address indexed receiver,
        address owner,
        address tokenAddress,
        uint256 amount
    );

    // @dev This emits when the contract owner changes the whitelisted tokens
    event TokenWhitelisted(
        address indexed token,
        address whitelistWallet,
        bool whitelisted
    );

    // @dev This emits when the funds are transferred using instant transfer method
    event InstantTokenTransfer(
        bytes32 name,
        address indexed crestWallet,
        address token,
        uint256 amount,
        address indexed receiver
    );

    // @dev This emits when the streams are created by the user
    event CreatedStream(
        bytes32 streamName,
        address streamSender,
        address streamReceiver,
        address streamingToken,
        uint256 streamStartTime,
        uint256 streamEndTime,
        uint256 streamingAmount,
        bytes32 indexed streamAddress,
        uint8 streamParam
    );

    // @dev This emits when the streams are stopped for streaming by the Owner
    event StoppedStreaming(
        bytes32 indexed streamAddress,
        address crestWallet,
        uint256 releasedAmount
    );

    // @dev This emits when the streams are paused for streaming by the Owner
    event PausedStreaming(
        bytes32 indexed streamAddress,
        uint256 pausedTime,
        uint256 releasableAmount
    );

    // @dev This emits when the streams are resumed for streaming by the Owner
    event ResumedStreaming(bytes32 indexed streamAddress, uint256 pausedAmount);

    // @dev This emits when the streams are updated by the Owner
    event UpdatedStream(
        bytes32 indexed streamAddress,
        bytes32 streamName,
        address crestWallet,
        uint256 streamStartTime,
        uint256 streamEndTime,
        uint256 streamAmount
    );

    // @dev This emits when the streams are withdrawn by the Receiver
    event WithdrawnStream(
        bytes32 indexed streamAddress,
        address crestWallet,
        address receiver,
        uint256 releasedAmount
    );

    // @dev This emits when the instant stream create is executed
    event CreatedCrestWalletAndStreamed(
        address indexed crestWallet,
        bytes32 streamAddress,
        address token,
        uint256 tokenAmount,
        address receiver
    );

    //@dev This emits when Bulk Transfer Stream is withdrawn for the first time
    event BulkTransferStreamed(
        address indexed receiver,
        address indexed sender,
        uint256 bulkTransferIndex,
        uint256 recurringFrequency
    );

    //@dev This emits when Bulk Transfer contract is updated
    event BulkTransferContractUpdated(address indexed contractAddress);

    //@dev This emits when Staking contract is updated
    event StakingContractUpdated(address indexed contractAddress);

    //@dev This emits when Bulk Instant Transfer  is withdrawn
    event BulkTransferInstantTransfer(
        uint256 bulkTransferIndex,
        address indexed receiver,
        address indexed sender,
        uint256 recurringFrequency
    );

    /**
     * @dev calculate the releasable amount for particular stream
     * @param streamBytes   stream address
     */
    function calculateReleasableAmount(
        bytes32 streamBytes
    ) external view returns (uint256 releaseAmount);

    /**
        @dev create stream
        @param streamName  name of stream
        @param streamingAmount     streaming amount of the tokens
        @param streamingToken      streaming tokens
        @param streamReceiverLabel receiver
        @param streamStartTime     start time
        @param streamEndTime       end time
        @param streamCancelable    param to be cancelable or not 
        @param streamPausable      stream param to be pausable or not 
    */
    function createStreamTNS(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        string memory streamReceiverLabel,
        uint256 streamStartTime,
        uint256 streamEndTime,
        bool streamCancelable,
        bool streamPausable
    ) external;

    /**
        @dev create stream
        @param streamName  name of stream
        @param streamingAmount  streaming amount of the tokens
        @param streamingToken   streaming tokens
        @param streamReceiver   receiver
        @param streamStartTime  start time
        @param streamEndTime    end time
        @param streamCancelable param to be cancelable or not 
        @param streamPausable   stream param to be pausable or not 
    */
    function createStream(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        address streamReceiver,
        uint256 streamStartTime,
        uint256 streamEndTime,
        bool streamCancelable,
        bool streamPausable
    ) external;

    /**
        @dev cancel stream by the sender
        @param streamBytes      stream address
     */
    function cancelStream(bytes32 streamBytes) external;

    /**
        @dev pause stream by the sender
        @param streamBytes      stream address
     */
    function pauseStream(bytes32 streamBytes) external;

    /**
        @dev resume stream by the sender
        @param streamBytes      stream address
     */
    function resumeStream(bytes32 streamBytes) external;

    /**
        @dev resume stream by the sender
        @param streamBytes      stream address
        @param name      stream name
        @param streamStartTime new stream Start Time
        @param streamEndTime new Stream End Time
        @param streamAmount new Stream Amount
     */
    function updateStream(
        bytes32 streamBytes,
        bytes32 name,
        uint256 streamStartTime,
        uint256 streamEndTime,
        uint256 streamAmount
    ) external;

    /**
        @dev withdraw stream by the receiver
        @param streamBytes          stream address
        @param withdrawAmount       amount to withdraw from the stream 
        @param crestWalletWithdraw  option to withdraw in the crest wallet 
     */
    function withdrawStream(
        bytes32 streamBytes,
        uint256 withdrawAmount,
        bool crestWalletWithdraw
    ) external;

    /**
        @dev add remove tokens from whitelist 
        @param tokens[]          tokens 
        @param isWhitelisted[]   tokens are whitelisted
     */
    function updateWhitelistedTokens(
        address[] memory tokens,
        bool[] memory isWhitelisted
    ) external;

    /**
        @dev deposit tokens on crest wallet 
        @param crestWallet   address in which to deposit 
        @param amount        amount to deposit
        @param tokenAddress  token to deposit
     */
    function depositTokens(
        address crestWallet,
        uint256 amount,
        address tokenAddress
    ) external payable;

    /**
        @dev withdraw token from the crest wallet
        @param amount       amount to withdraw from the vault
        @param tokenAddress token to withdraw from the vault
     */
    function withdrawTokens(uint256 amount, address tokenAddress) external;

    /**
        @dev instant token transfer from vault for tns domains
        @param name                 name of the instant transfer
        @param token                token address to send
        @param tokenAmount          amount to transfer
        @param receiverLabel        address to transfer to 
        @param CrestWalletWithdrawn is crest wallet withdraw
    */
    function instantTokenTransferTNS(
        bytes32 name,
        address token,
        uint256 tokenAmount,
        string memory receiverLabel,
        bool CrestWalletWithdrawn
    ) external payable;

    /**
        @dev instant token transfer from vault
        @param name                 name of the instant transfer
        @param token                token address to send
        @param tokenAmount          amount to transfer
        @param receiver             address to transfer to 
        @param crestWalletWithdraw  address to transfer to 
    */
    function instantTokenTransfer(
        bytes32 name,
        address token,
        uint256 tokenAmount,
        address receiver,
        bool crestWalletWithdraw
    ) external;

    /**
     * @dev Deposit the tokens on crest wallet and start the streaming
     *  @param streamName              name of stream
     * @param streamingAmount         amount of token for streaming
     * @param streamingToken          token to stream
     * @param streamReceiverLabel     stream receiver
     * @param streamStartTime         stream start time
     * @param streamEndTime           stream end time
     * @param streamCancelable        stream is cancelable
     * @param streamPausable          stream is pausable
     */
    function instantStreamTNS(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        string memory streamReceiverLabel,
        uint256 streamStartTime,
        uint256 streamEndTime,
        bool streamCancelable,
        bool streamPausable
    ) external payable;

    /**
     * @dev Deposit the tokens on crest wallet and start the streaming
     *  @param streamName  name of stream
     * @param streamingAmount         amount of token for streaming
     * @param streamingToken          token to stream
     * @param streamReceiver          stream receiver
     * @param streamStartTime         stream start time
     * @param streamEndTime           stream end time
     * @param streamCancelable        stream is cancelable
     * @param streamPausable          stream is pausable
     */
    function instantStream(
        bytes32 streamName,
        uint256 streamingAmount,
        address streamingToken,
        address streamReceiver,
        uint256 streamStartTime,
        uint256 streamEndTime,
        bool streamCancelable,
        bool streamPausable
    ) external payable;

    /**
     * @dev First Withdraw by the reciever to withdraw tokens for Bulk Transfer
     * @param bulkTransferIndex    bulk transfer index
     * @param transferingAmount    stream token amount
     * @param transferingToken     stream token
     * @param transferSender       stream creator / sender
     * @param transferReceiver     stream receiver
     * @param transferStartTime    stream start time
     * @param transferEndTime      stream end time
     * @param streamParam          stream is pausable
     * @param proofs               proofs
     * @param withdrawAmount       amount to withdraw
     * @param crestWalletWithdraw  withdraw in wallet
     */
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
        bool crestWalletWithdraw
    ) external;

    /**
     * @dev Withdraw by the reciever to withdraw tokens for Instant transfer for Bulk Transfer
     * @param bulkTransferIndex    bulk transfer index
     * @param transferingAmount    stream token amount
     * @param transferingToken     stream token
     * @param transferSender       stream creator / sender
     * @param transferReceiver     stream receiver
     * @param proofs               proof
     * @param crestWalletWithdraw  is crest wallet withdraw
     */
    function withdrawBulkInstantTransfer(
        uint256 bulkTransferIndex,
        uint256 transferingAmount,
        address transferingToken,
        address transferSender,
        address transferReceiver,
        bytes32[] memory proofs,
        bool crestWalletWithdraw
    ) external;
}
