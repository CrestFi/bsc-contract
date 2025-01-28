// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
async function main() {

  // const GnosisSafeL2 = await hre.ethers.getContractFactory("GnosisSafeL2");
  // const GnosisSafeL2Contract = await GnosisSafeL2.deploy();
  // await GnosisSafeL2Contract.waitForDeployment();
  // console.log("GnosisSafeL2 Deployed to: ", GnosisSafeL2Contract.target);

  // const Singleton = await hre.ethers.getContractFactory("Singleton");
  // const SingletonContract = await Singleton.deploy();
  // await SingletonContract.waitForDeployment();
  // console.log("Singleton Deployed to: ", SingletonContract.target);

  const GnosisSafeProxyFactory = await hre.ethers.getContractFactory("GnosisSafeProxyFactory");
  const GnosisSafeProxyFactoryContract = await GnosisSafeProxyFactory.deploy();
  await GnosisSafeProxyFactoryContract.waitForDeployment();
  console.log("GnosisSafeProxyFactory Deployed to: ", GnosisSafeProxyFactoryContract.target);

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
