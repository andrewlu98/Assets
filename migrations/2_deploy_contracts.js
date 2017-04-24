var ConvertLib = artifacts.require("ConvertLib");
var MetaCoin = artifacts.require("MetaCoin");
var EtherOpt = artifacts.require("EtherOpt");
var Contract = artifacts.require("Contract");
//var Master = artifacts.require("MasterContract");
//var Bilateral = artifacts.require("Bilateral");
//var SafeMath = artifacts.require("SafeMath");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  deployer.deploy(EtherOpt);
  deployer.deploy(Contract);
  //deployer.deploy(SafeMath);
  //deployer.deploy(MasterContract).then(function() {
  //	return deployer.deploy(Bilateral, MasterContract.address);
 // });
};
