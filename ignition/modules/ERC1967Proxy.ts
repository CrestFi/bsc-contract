// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const ERC1967ProxyModule = buildModule("ERC1967ProxyModule", (m) => {

  // for BulkTransfer
  // const ERC1967Proxy = m.contract("ERC1967Proxy", ["0x365B1FA833b243a7BE998FFEa1259FAF1c6917A2", "0x8129fc1c"]);


  // for Staking
  // const ERC1967Proxy = m.contract("ERC1967Proxy", ["0xEAFB401365d4478E333c34240C3e2DAB9A4e20b4", "0xc4d66de80000000000000000000000000000000000000000000000000000000000000000"]);

  // for Core
  const ERC1967Proxy = m.contract("ERC1967Proxy", ["0x19cf2e1eE247c13463BB72e21cc46303222c2052", "0x164af7c69a4ae42f1e070e47bb3b2fb6c84274e6ba285779c1ef81b6782d7613ce95047e8d98b85f0000f22ffe0866ffb8834600dad9259cf4956853"]);

  return { ERC1967Proxy };
});

export default ERC1967ProxyModule;
