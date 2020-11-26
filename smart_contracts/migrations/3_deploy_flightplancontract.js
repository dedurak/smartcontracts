var FlightPlanContracct = artifacts.require("FlightPlanContract");

module.exports = function(deployer) {
  deployer.deploy(FlightPlanContracct);
};
