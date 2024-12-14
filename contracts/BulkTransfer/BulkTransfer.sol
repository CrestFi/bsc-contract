// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./interface/IBulkTransfer.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@opengsn/contracts/src/ERC2771Recipient.sol";

contract BulkTransfer is
    IBulkTransfer,
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ERC2771Recipient
{

    struct Bulk {
        bytes32 name;
        bytes32 merkleRoots;
        uint8 transferType;
        uint256 startTime;
        //transfer type 0 for streams
        //transfer type 1 for instant transfer
    }

    // Error messages
    error EmptyMerkleRoot();
    error BulkTransferAlreadyStarted();
    error BulkTransferStartTimePast();
    error MissMatchBulkTransferType();

    mapping(address => uint256) public bulkCount;
    mapping(bytes32 => Bulk) public bulkTransfers;

    function initialize() public initializer {
        __Ownable_init(_msgSender());
    }

    // Function to create a new Bulk Transfer
    function createBulkTransfer(
        bytes32 _name,
        bytes32 _merkleRoot,
        uint256 _startTime,
        uint8 _transferType
    ) external override {
        // Checks if the start time is in the past
        if (_startTime <= block.timestamp) revert BulkTransferStartTimePast();

        // Calculate the bulkbytes for the new bulk transfer
        bytes32 bulkBytes = _calculateNextBulkBytes(_msgSender());

        // Create a new Bulk struct with the given arguments
        Bulk memory bulk = Bulk({
            name: _name,
            merkleRoots: _merkleRoot,
            startTime: _startTime,
            transferType: _transferType
        });

        // Stores the new bulk transfer in the bulkTransfers mapping
        bulkTransfers[bulkBytes] = bulk;

        // Increment the bulk transfer count for the sender
        bulkCount[_msgSender()] = bulkCount[_msgSender()] + (1);

        // Emits new bulk transfer creation event
        emit CreatedBulkTransfer(
            _name,
            _msgSender(),
            bulkCount[_msgSender()],
            _transferType
        );
    }

    // Function to update an existing Bulk Transfer
    function updateBulkTransfer(
        bytes32 _name,
        bytes32 bulkBytes,
        bytes32 merkleRoot,
        uint256 startTime
    ) external override {
        // Checkss if the start time is in the future
        if (startTime <= block.timestamp) revert BulkTransferStartTimePast();

        // Checkss if the merkle root is empty
        if (bulkTransfers[bulkBytes].merkleRoots == 0) revert EmptyMerkleRoot();

        // Checkss if the bulk transfer has already started, Cannot be updated if it has started
        if (bulkTransfers[bulkBytes].startTime <= block.timestamp)
            revert BulkTransferAlreadyStarted();

        // Update the existing bulk transfer with the new bulk transfer values
        bulkTransfers[bulkBytes] = Bulk({
            name: _name,
            merkleRoots: merkleRoot,
            startTime: startTime,
            transferType: bulkTransfers[bulkBytes].transferType
        });

        // Emit update of the bulk transfer event
        emit UpdatedBulkTransfer(_name, _msgSender(), bulkBytes);
    }

    // Function to verify an instant bulk transfer
    function verifyBulkInstantTransfer(
        uint256 bulkTransferIndex,
        uint256 transferingAmount,
        address transferingToken,
        address transferSender,
        address transferReceiver,
        bytes32[] memory proofs
    ) external view override returns (bool isValid) {
        // Calculate the bulk bytes for the bulk transfer
        bytes32 bulkBytes = calculateBulkBytes(
            transferSender,
            bulkTransferIndex
        );

        // Checks if the merkle root is empty
        if (bulkTransfers[bulkBytes].merkleRoots == 0) revert EmptyMerkleRoot();

        // Checks if the transfer type matches
        if (bulkTransfers[bulkBytes].transferType == 0)
            revert MissMatchBulkTransferType();

        bytes32 leaf;

        {
            // Calculate leaf node data using the arguments
            leaf = keccak256(
                bytes.concat(
                    keccak256(
                        abi.encode(
                            bulkTransferIndex,
                            transferingAmount,
                            transferingToken,
                            transferSender,
                            transferReceiver
                        )
                    )
                )
            );
        }

        {
            // Verifies the proof for the leafNode is valid in the merkle root
            isValid = MerkleProof.verify(
                proofs,
                bulkTransfers[bulkBytes].merkleRoots,
                leaf
            );
        }
    }

    // Function to verify a stream bulk transfer
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
    ) external view override returns (bool isValid) {
        // Calculate the bulk byte for the bulk transfer
        bytes32 bulkBytes = calculateBulkBytes(
            transferSender,
            bulkTransferIndex
        );

        // Checks if the merkle root is empty
        if (bulkTransfers[bulkBytes].merkleRoots == 0) revert EmptyMerkleRoot();

        // Checks if the transfer type matches
        if (bulkTransfers[bulkBytes].transferType == 1)
            revert MissMatchBulkTransferType();

        bytes32 leaf;
        {
            // Calculate leaf node data using the arguments
            leaf = keccak256(
                bytes.concat(
                    keccak256(
                        abi.encode(
                            bulkTransferIndex,
                            transferStartTime,
                            transferEndTime,
                            transferingAmount,
                            transferingToken,
                            transferSender,
                            transferReceiver,
                            streamParam
                        )
                    )
                )
            );
        }
        {
            // Verifies the proof for the leafNode is valid in the merkle root
            isValid = MerkleProof.verify(
                proofs,
                bulkTransfers[bulkBytes].merkleRoots,
                leaf
            );
        }
    }

    // Function to calculate the bulk Byte for a bulk transfer
    function calculateBulkBytes(
        address _sender,
        uint256 _bulkCount
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender, _bulkCount));
    }

    // Function to get the name of a bulk transfer
    function getBulkTransferName(
        address bulkSender,
        uint256 bulkTransferIndex
    ) public view override returns (bytes32 streamName) {
        bytes32 bulkBytes = calculateBulkBytes(bulkSender, bulkTransferIndex);
        streamName = bulkTransfers[bulkBytes].name;
    }

    // Function to get the start time of a bulk transfer
    function getBulkTransferStartTime(
        address bulkSender,
        uint256 bulkTransferIndex
    ) public view override returns (uint256 startTime) {
        bytes32 bulkBytes = calculateBulkBytes(bulkSender, bulkTransferIndex);
        startTime = bulkTransfers[bulkBytes].startTime;
    }

    // Internal function to calculate the bulk bytes for the next bulk transfer
    function _calculateNextBulkBytes(
        address _sender
    ) internal view returns (bytes32) {
        uint256 newBulkCount = bulkCount[_sender] +(1);
        return keccak256(abi.encodePacked(_sender, newBulkCount));
    }

    // Authorize contract upgrades
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

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
            // Extract sender address from the end of msg.data
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
}