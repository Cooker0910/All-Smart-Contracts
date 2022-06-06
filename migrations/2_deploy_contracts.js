var HelloWorld = artifacts.require("HelloWorld")
var Staking1 = artifacts.require("Staking1");

module.exports = function(deployer) {
  deployer.deploy(Staking1);
}