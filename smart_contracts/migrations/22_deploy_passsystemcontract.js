var PassSysContract = artifacts.require("PassSysContract");

module.exports = function(deployer) {
  deployer.deploy(PassSysContract);
};
