// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const CrestFiCore = await hre.ethers.getContractAt("CrestFiCore", "0x909c96948956303Dc3bc6Ac49445eE9e8195c962");

    const res = await CrestFiCore.getCrestWalletTokenBalance(["0xE0b9dEa53a90B7a2986356157e2812e5335A4a1D"], ["0x0000000000000000000000000000000000000000", "0x2C3F292dbae16420B441Fd277003a2EbD9eA4ED0"]);

    console.log(res, "===========res=========")
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
