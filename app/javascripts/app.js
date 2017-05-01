// Import the page's CSS. Webpack will know what to do with it.
import "../stylesheets/app.css";
import "../stylesheets/app1.css";

// Import libraries we need.
import { default as Web3} from 'web3';
import { default as contract } from 'truffle-contract';

// Import our contract artifacts and turn them into usable abstractions.
//import metacoin_artifacts from '../../build/contracts/MetaCoin.json';
//import etheropt_artifacts from '../../build/contracts/EtherOpt.json';
import master_artifacts from '../../build/contracts/Master.json';
import bilateral_artifacts from '../../build/contracts/Bilateral.json';
//import spawn_artifacts from '../../build/contracts/BilateralSpawn.json';

// MetaCoin is our usable abstraction, which we'll use through the code below.
//var MetaCoin = contract(metacoin_artifacts);
//var EtherOpt = contract(etheropt_artifacts);
var Master = contract(master_artifacts);
var Bilateral = contract(bilateral_artifacts);

// The following code is simple to show off interacting with your contracts.
// As your needs grow you will likely need to change its form and structure.
// For application bootstrapping, check out window.addEventListener below.
var accounts;
var account;

window.App = {
  start: function() {
    var self = this;

    // Bootstrap the MetaCoin abstraction for Use.
    //MetaCoin.setProvider(web3.currentProvider);
    Master.setProvider(web3.currentProvider);
    Bilateral.setProvider(web3.currentProvider);

    // Get the initial account balance so it can be displayed.
    web3.eth.getAccounts(function(err, accs) {
      if (err != null) {
        alert("There was an error fetching your accounts.");
        return;
      }

      if (accs.length == 0) {
        alert("Couldn't get any accounts! Make sure your Ethereum client is configured correctly.");
        return;
      }

      accounts = accs;
      account = accounts[0];

      //self.refreshBalance();
    });
  },

  setStatus: function(message) {
    var status = document.getElementById("status");
    status.innerHTML = message;
  },

  orderContract: function() {
    var self = this;

    var BilAddress = "0xbb2336b1b325afb5e82770aa20331c0a59373aae";
    var calladdr = document.getElementById("calladdr").value;
    var putaddr = document.getElementById("putaddr").value;
    var address = [BilAddress, calladdr, putaddr];
    var callhash = BilAddress;
    var puthash = BilAddress;
    var expr = parseInt(document.getElementById("expr").value);
    var upper = parseInt(document.getElementById("upper").value);
    var lower = parseInt(document.getElementById("lower").value);
    var prices = [upper, lower, 105, 95, 10];
    var sym = document.getElementById("sym").value;

    this.setStatus("Initiating order... (please wait)");

    var option;

    Master.defaults({
      from: account,
      gas: 1000000,
      gasPrice: 100,
      value: 0
    });

    Master.deployed().then(function(instance) {
      option = instance;
      return option.AddAgreement(address, callhash, puthash, expr, prices, sym, {from: account});
    }).then(function() {
      self.setStatus("Order complete!");
    }).catch(function(e) {
      console.log(e);
      self.setStatus("Error completing order.");
    }); 
  },
};

window.addEventListener('load', function() {
  // Checking if Web3 has been injected by the browser (Mist/MetaMask)
  if (typeof web3 !== 'undefined') {
    console.warn("Using web3 detected from external source. If you find that your accounts don't appear or you have 0 MetaCoin, ensure you've configured that source properly. If using MetaMask, see the following link. Feel free to delete this warning. :) http://truffleframework.com/tutorials/truffle-and-metamask")
    // Use Mist/MetaMask's provider
    window.web3 = new Web3(web3.currentProvider);
  } else {
    console.warn("No web3 detected. Falling back to http://localhost:8545. You should remove this fallback when you deploy live, as it's inherently insecure. Consider switching to Metamask for development. More info here: http://truffleframework.com/tutorials/truffle-and-metamask");
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    window.web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
  }

  App.start();
});
