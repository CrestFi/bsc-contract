// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const BulkTransferModule = buildModule("BulkTransferModule", (m) => {
  const bulkTransfer = m.contract("BulkTransfer", []);

  return { bulkTransfer };
});

export default BulkTransferModule;
