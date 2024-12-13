import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const BSCSCAN_API_KEY = vars.get("BSCSCAN_API_KEY");

const BSC_TESTNET_PRIVATE_KEY = vars.get("BSC_TESTNET_PRIVATE_KEY");
const BSC_MAINNET_PRIVATE_KEY = vars.get("BSC_MAINNET_PRIVATE_KEY");

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100
      },
      viaIR: true,
    }
  },
  networks: {
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [BSC_TESTNET_PRIVATE_KEY],
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [BSC_MAINNET_PRIVATE_KEY],
    }
  },
  etherscan: {
    apiKey: BSCSCAN_API_KEY
  },
};

export default config;
