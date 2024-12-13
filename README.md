# CrestFi BSC Contract

Configuration Variable (stored in $HOME/.config/hardhat-nodejs/vars.json)

```shell
npx hardhat vars list
npx hardhat vars get BSCSCAN_API_KEY
npx hardhat vars set BSC_TESTNET_PRIVATE_KEY
npx hardhat vars delete BSC_TESTNET_PRIVATE_KEY
```

Compile, Deploy and Verify:

```shell
npx hardhat compile
npx hardhat ignition deploy ./ignition/modules/Core.ts --network testnet --verify
```