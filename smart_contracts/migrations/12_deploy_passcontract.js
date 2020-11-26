var passContract = artifacts.require("passContract");

module.exports = function(deployer) {
  deployer.deploy(passContract);
};
