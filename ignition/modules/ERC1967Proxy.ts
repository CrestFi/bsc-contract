// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ERC1967ProxyModule = buildModule("ERC1967ProxyModule", (m) => {
  const ERC1967Proxy = m.contract("ERC1967Proxy", []);

  return { ERC1967Proxy };
});

export default ERC1967ProxyModule;
