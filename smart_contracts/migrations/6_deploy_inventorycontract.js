var InventoryContract = artifacts.require("InventoryContract");

module.exports = function(deployer) {
  deployer.deploy(InventoryContract);
};
