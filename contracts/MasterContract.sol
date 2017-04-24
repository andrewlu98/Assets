pragma solidity ^0.4.2;

import "../contracts/Bilateral.sol";

contract SafeMath {
    //internals

    function safeMul(uint a, uint b) internal returns (uint) {
uint c = a * b;
assert(a ==  0 || c / a ==  b);
return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
assert(b <=  a);
return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
uint c = a + b;
assert(c>= a && c>= b);
return c;
    }

    function safeMuli(int a, int b) internal returns (int) {
int c = a * b;
assert(a ==  0 || c / a ==  b);
return c;
    }

    function safeSubi(int a, int b) internal returns (int) {
int negB = safeNegi(b);
int c = a + negB;
if (b<0 && c<= a) throw;
if (a>0 && b<0 && c<= 0) throw;
if (a<0 && b>0 && c>= 0) throw;
return c;
    }

    function safeAddi(int a, int b) internal returns (int) {
int c = a + b;
if (a>0 && b>0 && c<= 0) throw;
if (a<0 && b<0 && c>= 0) throw;
return c;
    }

    function safeNegi(int a) internal returns (int) {
int c = -a;
if (a<0 && -a<= 0) throw;
return c;
    }

    function safeIntToUint(int a) internal returns(uint) {
uint c = uint(a);
assert(a>= 0);
return c;
    }

    function safeUintToInt(uint a) internal returns(int) {
int c = int(a);
assert(c>= 0);
return c;
    }

    function assert(bool assertion) internal {
if (!assertion) throw;
    }
}


contract MasterContract is SafeMath {

	uint public version = 1;
	address public MasterContractAddress = this;
	struct Account {
		address   user;
		int    capital;
		bytes32 secret; //Default is 0
	}
	mapping(uint  => Account) accounts;
	uint public numAccounts;
	mapping(address  => uint) accountIDs; //starts at 1

	address admin;

	//events
	event Deposit(address indexed user, uint amount, int balance); //balance is balance after deposit
	event Withdraw(address indexed user, uint amount, int balance); //balance is balance after withdraw
	event NewOrder(address contractadress, string symbol, address calladdr, address putaddr, uint expirationtime, uint callprice, uint putprice) ;
	event SecretUpdated(address user);
	event Matchfail(address user, bytes32 orderhash);
    event MatchfailFunds(address user, string message);


	function MasterContract(){
		admin = msg.sender; //So far the admin has no special powers....
		MasterContractAddress = this;

	}

	function getMasterAddress() returns (address) {
	    return this;
	}

    function() payable { //Fallback Function deposits money to the user account
        addFunds();
    }

	function CheckHash(string symbol, address addr, bytes32 hash, uint expirationtime, uint price, uint target) returns(bool) {
		bytes32  secret = accounts[accountIDs[addr]].secret;
		if (sha256(secret, symbol, price, target, expirationtime) == hash) {
			return true;
			} else{
		return false;
			}
}

	function AddAgreement(string symbol, address calladdr, bytes32 callhash, address putaddr, bytes32 puthash, uint expirationtime, uint callprice, uint putprice, uint calltarget, uint puttarget) returns(bool) 
		{
		bool callbool;
		bool putbool;
        // Check all conditions again... such as sufficient capital
        callbool = (accounts[accountIDs[calladdr]].capital >= safeUintToInt(callprice));
        if (!callbool) {
            MatchfailFunds(calladdr, 'Insufficient funds');
            return false;
        }
        putbool = (accounts[accountIDs[putaddr]].capital >= safeUintToInt(putprice));
        if (!putbool) {
            MatchfailFunds(putaddr, 'Insufficient funds');
            return false;
        }
		// .... (but also the others) 

        //Check integrity of information
		callbool = CheckHash(symbol, calladdr, callhash, expirationtime, callprice, calltarget);
		putbool  = CheckHash(symbol, putaddr, puthash, expirationtime, putprice, puttarget); 

		if (callbool && putbool){

        //if (true){ //For testing 

			uint Difference = safeSub(callprice, putprice);
			uint agreementfee = Difference/200;
			uint BiliteralValue = safeSub(Difference, agreementfee);

            // Update Account balances
            accounts[accountIDs[calladdr]].capital = safeSubi(accounts[accountIDs[calladdr]].capital, safeUintToInt(callprice));
            accounts[accountIDs[putaddr]].capital  = safeSubi(accounts[accountIDs[putaddr]].capital, safeUintToInt(putprice));

            // Initialise Agreement Contract
			Bilateral agreementContract = new Bilateral(calladdr, putaddr, expirationtime, calltarget, puttarget, symbol);
			agreementContract.TestFunc(this);
			bool store = agreementContract.call.gas(200000).value(BiliteralValue)();
			NewOrder(agreementContract, symbol, calladdr, putaddr, expirationtime, callprice, putprice) ;
			return true;
		} else if (!callbool) {
			Matchfail(calladdr, callhash);
			return false;
		} else {
			Matchfail(putaddr, puthash);
			return false;

		}
	}

	function getAccountID(address user) constant returns(uint) {
		return accountIDs[user];
	}

	function getAccount(uint accountID) constant returns(address) {
		return accounts[accountID].user;
	}

	function SetSecret(bytes32 _secret) {
		if (accountIDs[msg.sender]>0) { // We allow changing the secret -  this will render all previous orders invalid
            bytes32 oldsecret= accounts[accountIDs[msg.sender]].secret;
            if (oldsecret != _secret){
    	       accounts[accountIDs[msg.sender]].secret = _secret;
    	       SecretUpdated(msg.sender);
            }
	   } else {
    		uint accountID = ++numAccounts;
    		accountIDs[msg.sender] = accountID;
    		accounts[accountID].user = msg.sender;
    		accounts[accountID].secret = _secret;
    	}
    	SecretUpdated(msg.sender);
	}


	function addFunds() payable {
	   if (accountIDs[msg.sender]>0) {
	       accounts[accountIDs[msg.sender]].capital = safeAddi(accounts[accountIDs[msg.sender]].capital, safeUintToInt(msg.value));
		} else {
        	uint accountID = ++numAccounts;
        	accountIDs[msg.sender] = accountID;
        	accounts[accountID].user = msg.sender;
        	accounts[accountID].capital = safeAddi(accounts[accountID].capital, safeUintToInt(msg.value));
		}
    	Deposit(msg.sender, msg.value, accounts[accountIDs[msg.sender]].capital);
	}


	function addFundsToaddress(address beneficiary) payable {
    	if (accountIDs[beneficiary]>0) {
    		accounts[accountIDs[beneficiary]].capital = safeAddi(accounts[accountIDs[beneficiary]].capital, safeUintToInt(msg.value));
    	} else {
        	uint accountID = ++numAccounts;
        	accountIDs[beneficiary] = accountID;
        	accounts[accountID].user = beneficiary;
        	accounts[accountID].capital = safeAddi(accounts[accountID].capital, safeUintToInt(msg.value));
		}
    	Deposit(beneficiary, msg.value, accounts[accountIDs[beneficiary]].capital);
	}



	function withdrawFunds(uint amount) {
		if (accountIDs[msg.sender]<= 0) throw;
		int amountInt = safeUintToInt(amount);
		if (amountInt > getFunds(msg.sender) || amountInt <= 0) throw;
		accounts[accountIDs[msg.sender]].capital = safeSubi(accounts[accountIDs[msg.sender]].capital, amountInt);
		if (!msg.sender.call.value(amount)()) throw;
		Withdraw(msg.sender, amount, accounts[accountIDs[msg.sender]].capital);
	}

	function getFunds(address user) constant returns(int) {
		if (accountIDs[user]<= 0) return 0;
		return accounts[accountIDs[user]].capital;
		}
	}




