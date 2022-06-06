var HelloWorld = artifacts.require("HelloWorld")
var Staking1 = artifacts.require("Staking1");

module.exports = function(deployer) {
  var stakingToken = '0x9A3a08544d50A60bB89526f52C1D4788e3DD9292';
  var rewardToken = '0x9A3a08544d50A60bB89526f52C1D4788e3DD9292'
  deployer.deploy(Staking1, stakingToken, rewardToken)
}