// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
async function main() {

  const USDT = await hre.ethers.getContractFactory("USDT");
  const USDTContract = await USDT.deploy();
  await USDTContract.waitForDeployment();
  console.log("USDT Deployed to: ", USDTContract.target);

  const CFT = await hre.ethers.getContractFactory("CFT");
  const CFTContract = await CFT.deploy();
  await CFTContract.waitForDeployment();
  console.log("CFT Deployed to: ", CFTContract.target);

  const BulkTransfer = await hre.ethers.getContractFactory("BulkTransfer");
  const BulkTransferContract = await hre.upgrades.deployProxy(BulkTransfer, [], { initializer: 'initialize' });
  await BulkTransferContract.waitForDeployment();
  console.log("BulkTransfer Deployed to: ", BulkTransferContract.target);

  const Staking = await hre.ethers.getContractFactory("Staking");
  const StakingContract = await hre.upgrades.deployProxy(Staking, [CFTContract.target], { initializer: 'initialize' });
  await StakingContract.waitForDeployment();
  console.log("Staking Deployed to: ", StakingContract.target);

  const Registry = await hre.ethers.getContractFactory("Registry");
  const RegistryContract = await Registry.deploy();
  await RegistryContract.waitForDeployment();
  console.log("Registry Deployed to: ", RegistryContract.target);

  const CrestFiCore = await hre.ethers.getContractFactory("CrestFiCore");
  const CrestFiCoreContract = await hre.upgrades.deployProxy(CrestFiCore, [StakingContract.target, BulkTransferContract.target, RegistryContract.target], { initializer: 'initialize' });
  await CrestFiCoreContract.waitForDeployment();
  console.log("CrestFiCore Deployed to: ", CrestFiCoreContract.target);

}

async function verify_contract() {
  await hre.run("verify:verify", {
    address: "0x912688eBBf5d9FE1CcbDFBF281b55ba3AD31F450",
    constructorArguments: [],
  });

  console.log("Contract verified successfully!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
