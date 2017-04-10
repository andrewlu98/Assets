var ConvertLib = artifacts.require("ConvertLib");
var MetaCoin = artifacts.require("MetaCoin");
var EtherOpt = artifacts.require("EtherOpt");
var Contract = artifacts.require("Contract");

module.exports = function(deployer) {
  deployer.deploy(ConvertLib);
  deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(MetaCoin);
  deployer.deploy(EtherOpt);
  deployer.deploy(Contract);
};
