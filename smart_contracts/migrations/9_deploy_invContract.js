var InvContract = artifacts.require("InvContract");

module.exports = function(deployer) {
  deployer.deploy(InvContract);
};
