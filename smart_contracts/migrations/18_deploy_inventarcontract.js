var InventarContract = artifacts.require("InventarContract");

module.exports = function(deployer) {
  deployer.deploy(InventarContract);
};
