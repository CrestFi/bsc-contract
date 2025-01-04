// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.28;

import "../interface/IBulkTransfer.sol";

library BulkTransferLibrary {
    //Error Messages
    error BulkTransferInvalidProof();
    error BulkTransferNotStarted();

    // Performs verification for instant bulk transfers
    function instantBulkTransferVerification(
        IBulkTransfer bulkTransfer,
        uint256 bulkTransferIndex,
        uint256 transferAmount,
        address transferToken,
        address transferSender,
        address transferReceiver,
        uint256 recurringFrequency,
        bytes32[] memory proofs
    ) internal view returns (bytes32 streamName) {
        // Verify the bulk instant transfer with the provided proofs

        if (
            !bulkTransfer.verifyBulkInstantTransfer(
                bulkTransferIndex,
                transferAmount,
                transferToken,
                transferSender,
                transferReceiver,
                proofs
            )
        ) revert BulkTransferInvalidProof();

        // Check if the bulk transfer has started
        if (
            bulkTransfer.getBulkTransferStartTime(
                transferSender,
                bulkTransferIndex,
                recurringFrequency
            ) >= block.timestamp
        ) revert BulkTransferNotStarted();

        // Get the stream name of the bulk transfer
        streamName = bulkTransfer.getBulkTransferName(
            transferSender,
            bulkTransferIndex
        );
    }

    // Performs verification for bulk streams
    function bulkStreamVerification(
        IBulkTransfer bulkTransfer,
        uint256 bulkTransferIndex,
        uint256 transferAmount,
        address transferToken,
        address transferSender,
        address transferReceiver,
        uint256 transferStartTime,
        uint256 transferEndTime,
        uint256 recurringFrequency,
        uint8 streamParam,
        bytes32[] memory proofs
    ) internal view returns (bytes32 streamName) {
        // Verify the bulk stream transfer with the provided proofs
        if (
            !bulkTransfer.verifyBulkStreamTransfer(
                bulkTransferIndex,
                transferAmount,
                transferToken,
                transferSender,
                transferReceiver,
                transferStartTime,
                transferEndTime,
                streamParam,
                proofs
            )
        ) revert BulkTransferInvalidProof();

        // Check if the bulk transfer has started
        if (
            bulkTransfer.getBulkTransferStartTime(
                transferSender,
                bulkTransferIndex,
                recurringFrequency
            ) >= block.timestamp
        ) revert BulkTransferNotStarted();

        // Get the stream name of the  the bulk transfer
        streamName = bulkTransfer.getBulkTransferName(
            transferSender,
            bulkTransferIndex
        );
    }
}