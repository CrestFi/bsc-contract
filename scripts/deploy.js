// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {

  // const USDT = await hre.ethers.getContractFactory("USDT");
  // const USDTContract = await USDT.deploy();
  // await USDTContract.waitForDeployment();
  // console.log("CTN Deployed to: ", USDTContract.target);

  // const CTN = await hre.ethers.getContractFactory("CTN");
  // const CTNContract = await CTN.deploy();
  // await CTNContract.waitForDeployment();
  // console.log("CTN Deployed to: ", CTNContract.target);

  // const BulkTransfer = await hre.ethers.getContractFactory("BulkTransfer");
  // const BulkTransferContract = await hre.upgrades.deployProxy(BulkTransfer, [], { initializer: 'initialize' });
  // await BulkTransferContract.waitForDeployment();
  // console.log("BulkTransfer Deployed to: ", BulkTransferContract.target);

  // const Staking = await hre.ethers.getContractFactory("Staking");
  // const StakingContract = await hre.upgrades.deployProxy(Staking, [CTNContract.target], { initializer: 'initialize' });
  // await StakingContract.waitForDeployment();
  // console.log("Staking Deployed to: ", StakingContract.target);

  // const Registry = await hre.ethers.getContractFactory("Registry");
  // const RegistryContract = await Registry.deploy();
  // await RegistryContract.waitForDeployment();
  // console.log("Registry Deployed to: ", RegistryContract.target);

  const CrestFiCore = await hre.ethers.getContractFactory("CrestFiCore");
  const CrestFiCoreContract = await hre.upgrades.deployProxy(CrestFiCore, ["0xfb7cfF2d7a811Bed4C52d1A96661E386a860F3d2", "0xd869D0f42aA904e6E67dB3532D7C252d71122F39", "0xa33a7d4553565724841cdAeCC5DDD4638A47C855"], { initializer: 'initialize' });
  await CrestFiCoreContract.waitForDeployment();
  console.log("CrestFiCore Deployed to: ", CrestFiCoreContract.target);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
