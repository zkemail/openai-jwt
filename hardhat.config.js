require("hardhat-circom");
require("@nomicfoundation/hardhat-toolbox");
let secret = require("./secret");


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.6.11",
      },
      {
        version: "0.8.9",
      },
    ],
  },
  networks: {
    goerli: {
      url: secret.goerli,
      accounts: [secret.key],
      gas: 35000000,
      gasPrice: 8000000000
    }
  },
  allowUnlimitedContractSize: true,
  circom: {
    inputBasePath: "./circuits",
    ptau: "powersOfTau28_hez_final_22.ptau",
    circuits: [
      // {
      //   name: "utils",
      //   protocol: "groth16"

      // }, 
      // {
      //   name: "jwt_type_regex",
      //   input: "jwt_type_regex.json"
      // },
      {
        name: "jwt",
        protocol: "groth16"
      }
    ],
  },
};
