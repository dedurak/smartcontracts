const HDWalletProvider = require('truffle-hdwallet-provider');
const fs = require('fs');

let secrets;

if(fs.existsSync('secrets.json')) {
    secrets = JSON.parse(fs.readFileSync('secrets.json', 'utf-8'));
}

module.exports = {
    networks: {
        rinkeby: {
            provider: new HDWalletProvider(secrets.mnemonic, "https://rinkeby.infura.io/v3/"+secrets.infuraApiKey),
            network_id: '4',
            gas: 3000000,
            gasPrice: 1000000000
        }
    },

    compilers: {
        solc: {
          version: "0.6.7",    // Fetch exact version from solc-bin (default: truffle's version)
          // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
          // settings: {          // See the solidity docs for advice about optimization and evmVersion
          //  optimizer: {
          //    enabled: false,
          //    runs: 200
          //  },
          //  evmVersion: "byzantium"
          // }
        }
      }
};
