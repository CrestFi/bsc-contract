// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IBulkTransfer {

    // @dev This emits when the bulk tansfer is created
    event CreatedBulkTransfer(
        bytes32 name,
        address indexed sender,
        uint256 bulkCount,
        uint8 transferType
    );

    // @dev This emits when the bulk tansfer is updated
    event UpdatedBulkTransfer(
        bytes32 name,
        address indexed sender,
        bytes32 bulkBytes
    );
    // @dev This emits when the bulk tansfer is cancelled
    event CancelledBulkTransfer(address indexed sender, bytes32 bulkBytes);

    /**
     * @dev create a new bulk transfer by setting the merkle root and relevant informations
     * @param name    the merkle root to set for new bulk transfer
     * @param merkleRoot    the merkle root to set for new bulk transfer
     * @param startTime     the start time for new bulk transfer
     * @param transferType  the type of transfer
     * @param recurringFrequency recurring Frequency
     * @param startTimes recurring interval
     */
    function createBulkTransfer(
        bytes32 name,
        bytes32 merkleRoot,
        uint256 startTime,
        uint8 transferType,
        uint256[] calldata startTimes,
        uint256 recurringFrequency
    ) external;

    /**
     * @dev update a bulk transfer
     * @param name  updated stream name
     * @param bulkTransferIndex  bulk bytes to update
     * @param merkleRoot updated merkle root to set for
     * @param startTime  the start time for new bulk transfer
     * @param _recurringFrequency recurring Frequency
     * @param startTimes recurring interval
     */
    function updateBulkTransfer(
        bytes32 name,
        uint256 bulkTransferIndex,
        bytes32 merkleRoot,
        uint256 startTime,
        uint256 _recurringFrequency,
        uint256[] calldata startTimes
    ) external;

    /**
     * @dev update a bulk transfer
     * @param bulkTransferIndex  bulk transfer Index to cancel for the caller
     */

    function cancelBulkTransfer(uint256 bulkTransferIndex) external;

    /**
     * @dev core contract calls this view function to verify if the given data is valid for the given transfer
     * @param bulkTransferIndex    bulk transfer index
     * @param transferingAmount    stream token amount
     * @param transferingToken     stream token
     * @param transferSender       stream creator / sender
     * @param transferReceiver     stream receiver
     * @param transferStartTime    stream start time
     * @param transferEndTime      stream end time
     * @param streamParam          stream is cancelable & pausable
     * @param proofs               proofs
     */
    function verifyBulkStreamTransfer(
        uint256 bulkTransferIndex,
        uint256 transferingAmount,
        address transferingToken,
        address transferSender,
        address transferReceiver,
        uint256 transferStartTime,
        uint256 transferEndTime,
        uint8 streamParam,
        bytes32[] memory proofs
    ) external view returns (bool);

    /**
     * @dev   verify the bulk transfer
     * @param bulkTransferIndex bulk transfer index for the transfer
     * @param transferingAmount amount for the transfer
     * @param transferingToken  address of the token
     * @param transferSender    transfer sender address
     * @param transferReceiver  transfer receiver address
     * @param proofs               proofs
     */
    function verifyBulkInstantTransfer(
        uint256 bulkTransferIndex,
        uint256 transferingAmount,
        address transferingToken,
        address transferSender,
        address transferReceiver,
        bytes32[] memory proofs
    ) external view returns (bool);

    /**
     * @dev core contract calls this view function to get the start time of the Bulk Transfer
     * @param bulkSender        bulk sender
     * @param bulkTransferIndex bulk transfer index of bulk sender
     * @param recurringFrequency recurring index of the single transaction
     */
    function getBulkTransferStartTime(
        address bulkSender,
        uint256 bulkTransferIndex,
        uint256 recurringFrequency
    ) external view returns (uint256);

    /**
     * @dev core contract calls this view function to get the name of the Bulk Transfer
     * @param bulkSender        bulk sender
     * @param bulkTransferIndex bulk transfer index of bulk sender
     */
    function getBulkTransferName(
        address bulkSender,
        uint256 bulkTransferIndex
    ) external view returns (bytes32);

    /**
     * @dev core contract calls this view function to get the name of the Bulk Transfer
     * @param bulkSender        bulk sender
     * @param bulkTransferIndex bulk transfer index of bulk sender
     */
    function getBulkTransferRecurringFrequency(
        address bulkSender,
        uint256 bulkTransferIndex
    ) external view returns (uint256);

        /**
     * @dev core contract calls this view function to get the name of the Bulk Transfer
     * @param bulkSender        bulk sender
     * @param bulkTransferIndex bulk transfer index of bulk sender
     */
    function getBestRecurringFrequencyBasedOnStartTime(
        address bulkSender,
        uint256 bulkTransferIndex
    ) external view returns (uint256);
}
