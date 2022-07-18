import "@nomiclabs/hardhat-waffle"
import { task } from "hardhat/config";
import { wallet } from "./config/consts";
import "@nomiclabs/hardhat-solpp";
import "@nomiclabs/hardhat-ethers";
import '@nomiclabs/hardhat-etherscan';

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
export default {
  solidity: {
    compilers: [
      {
        version: '0.8.13',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  //defaultNetwork: "OxMainnet",
  defaultNetwork: "localhost",
  networks: {
    localhost: {
      'url': 'http://127.0.0.1:8545',
      timeout: 30000
    },
    OxMainnet: {
      url: "https://polygon-rpc.com",
      chainId: 137,
      accounts: [wallet.privateKey]
    }
  },
  etherscan: {
    apiKey: 'J216UIQZC5WPZNQIKD1CX38C8X8CVAQPAA'
  },
  solpp: {
    defs: {
      DEV_MODE: 1
    }
  }
};
