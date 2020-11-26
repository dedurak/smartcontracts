var InventContract = artifacts.require("InventContract");

module.exports = function(deployer) {
  deployer.deploy(InventContract);
};
