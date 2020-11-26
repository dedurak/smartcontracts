var PassSystemContract = artifacts.require("PassSystemContract");

module.exports = function(deployer) {
  deployer.deploy(PassSystemContract);
};
