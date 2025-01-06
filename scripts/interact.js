// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
    const BulkTransfer = await hre.ethers.getContractAt("BulkTransfer", "0xd869D0f42aA904e6E67dB3532D7C252d71122F39");

    await BulkTransfer.createBulkTransfer(["Test", "bd318e1cb094ba7fa8fca7df7947a642d621735828b7e9f66afd7bd0e650009d", 1736982356, 1, [1736982356], 1736982356]);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
