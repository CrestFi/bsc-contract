require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

require("dotenv").config();

const {
  API_URL_BNB,
  PRIVATE_KEY,
} = process.env;
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  paths: {
    artifacts: "./src/artifacts",
  },
  mocha: {
    timeout: 30000000,
  },

  sourcify: {
    enabled: true
  },

  defaultNetwork: "bsc_testnet",
  networks: {
    hardhat: {},
    bsc_testnet: {
      url: API_URL_BNB,
      allowUnlimitedContractSize: true,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: {
      bsc: "IVJRG3JPZ1A8RPU6CTP9P3Z7ZZ5USC6JUM",
      bscTestnet: "IVJRG3JPZ1A8RPU6CTP9P3Z7ZZ5USC6JUM",
    },
  },
};
