var PassengerSystem = artifacts.require("PassengerSystem");

module.exports = function(deployer) {
  deployer.deploy(PassengerSystem);
};
