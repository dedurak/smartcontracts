var FlightPlan = artifacts.require("FlightPlan");

module.exports = function(deployer) {
  deployer.deploy(FlightPlan);
};
