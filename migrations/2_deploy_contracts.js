var EtherOpt = artifacts.require("EtherOpt");
var Contract = artifacts.require("Contract");
var Master = artifacts.require("Master");
var Bilateral = artifacts.require("Bilateral");
var SafeMath = artifacts.require("SafeMath");
//var BilateralSpawn = artifacts.require("BilateralSpawn");

module.exports = function(deployer) {
  deployer.deploy(EtherOpt);
  deployer.deploy(Contract);
  deployer.deploy(SafeMath);
  deployer.deploy(Master);
  deployer.deploy(Bilateral);
  //deployer.deploy(BilateralSpawn);
  // deployer.deploy(Master).then(function() {
  // 	return deployer.deploy(Bilateral, Master.address);
  // });
};
