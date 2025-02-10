require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");

require("dotenv").config();

const {
  API_URL_BNB,
  API_URL_BASE,
  MAIN_API_URL_BNB,
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

  defaultNetwork: "base_testnet",
  networks: {
    hardhat: {},
    bsc_testnet: {
      url: API_URL_BNB,
      allowUnlimitedContractSize: true,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    bsc_mainnet: {
      url: MAIN_API_URL_BNB,
      allowUnlimitedContractSize: true,
      accounts: [`0x${PRIVATE_KEY}`],
      gasPrice: 1000000000,
    },
    base_testnet: {
      url: API_URL_BASE,
      allowUnlimitedContractSize: true,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
  etherscan: {
    apiKey: {
      bsc: "6PK7F5P5MUYI2QYXSAEWSZYWQ4HI63KK29",
      bscTestnet: "6PK7F5P5MUYI2QYXSAEWSZYWQ4HI63KK29",
      baseSepolia:"R39ZWKAA7K7CFBS9XJ3GPDEHMY33MI4DBR",
    },
  },
};
