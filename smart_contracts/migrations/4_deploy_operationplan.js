var OperationPlan = artifacts.require("OperationPlan");

module.exports = function(deployer) {
  deployer.deploy(OperationPlan);
};
