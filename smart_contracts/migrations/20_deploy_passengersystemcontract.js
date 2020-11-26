var PassengerSystemContract = artifacts.require("PassengerSystemContract");

module.exports = function(deployer) {
  deployer.deploy(PassengerSystemContract);
};
