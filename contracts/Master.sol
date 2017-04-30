	pragma solidity ^0.4.8;

	contract Bilateral {
			function AddBilateral(string symbol, address CallAddr, address PutAddr, uint256 ExpTime, uint Upper, uint Lower) payable {}
			}

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


	contract Master is SafeMath {

		uint public version = 1;
		address public MasterContractAddress = this;
		struct Account {
			address   user;
			uint    capital;
			bytes32 secret; //Default is 0
		}
		mapping(uint  => Account) accounts;
		uint public numAccounts;
		mapping(address  => uint) accountIDs; //starts at 1

		address admin;

		//events
		event Deposit(address indexed user, uint amount, uint balance); //balance is balance after deposit
		event Withdraw(address indexed user, uint amount, uint balance); //balance is balance after withdraw
		event NewOrder(address contractadress, string symbol, address calladdr, address putaddr, uint expirationtime, uint callprice, uint putprice, uint quantity) ;
		event SecretUpdated(address user);
		event Matchfail(address user, bytes32 orderhash);
		event MatchfailFunds(address user, string message);


		function Master(){
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

		function CheckAgreement(address[3] Addresses, bytes32 callhash, bytes32 puthash, uint expirationtime, uint[5] prices, string symbol) returns(bool) {
			uint callid = getAccountID(Addresses[1]);
			uint putid = getAccountID(Addresses[2]);
			if (accounts[callid].capital <= prices[0]) {
				MatchfailFunds(Addresses[1], 'Insufficient funds');
				return false;
			}
			if (accounts[callid].capital <= prices[1]) {
				MatchfailFunds(Addresses[2], 'Insufficient funds');
				return false;
			}
			bytes32  secret1 = accounts[callid].secret;
			bytes32  secret2 = accounts[putid].secret;
			if ((sha256(secret1, symbol, prices[0], prices[2], expirationtime) == callhash) && (sha256(secret2, symbol, prices[1], prices[3], expirationtime) == puthash)) {
				return true;
				} else{
					return false;
				}
		}



		function AddAgreement(address[3] Addresses, bytes32 callhash, bytes32 puthash, uint expirationtime, uint[5] prices, string symbol) payable returns(bool) {
		// prices = uint callprice, uint putprice, uint calltarget, uint puttarget, quantity
		// address = BilAddress, calladdr, putaddr
			uint callid = getAccountID(Addresses[1]);
			uint putid = getAccountID(Addresses[2]);
			if (!CheckAgreement(Addresses,  callhash,  puthash,  expirationtime, prices, symbol)){
				return false;
			}

			// Update Account balances
			accounts[callid].capital = safeSub(accounts[callid].capital, prices[0]);
			accounts[putid].capital  = safeSub(accounts[putid].capital, prices[1]);


			uint BiliteralValue = safeMul(prices[4],safeSub(prices[0],prices[1])*199/200); //This takes a 0.5% fee to cover gas costs
			// Initialise Agreement Contract

			Bilateral BilC = Bilateral(Addresses[0]);
			BilC.AddBilateral.value(BiliteralValue) (symbol, Addresses[1], Addresses[2], expirationtime, prices[0], prices[1]);
			NewOrder(BilC, symbol, Addresses[1], Addresses[2], expirationtime, prices[0], prices[1], prices[4]) ;
			return true;
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
				accounts[accountIDs[msg.sender]].capital = safeAdd(accounts[accountIDs[msg.sender]].capital, msg.value);
				} else {
					uint accountID = ++numAccounts;
					accountIDs[msg.sender] = accountID;
					accounts[accountID].user = msg.sender;
					accounts[accountID].capital = safeAdd(accounts[accountID].capital, msg.value);
				}
				Deposit(msg.sender, msg.value, accounts[accountIDs[msg.sender]].capital);
			}


		function addFundsToaddress(address beneficiary) payable {
			if (accountIDs[beneficiary]>0) {
				accounts[accountIDs[beneficiary]].capital = safeAdd(accounts[accountIDs[beneficiary]].capital, msg.value);
				} else {
					uint accountID = ++numAccounts;
					accountIDs[beneficiary] = accountID;
					accounts[accountID].user = beneficiary;
					accounts[accountID].capital = safeAdd(accounts[accountID].capital, msg.value);
				}
				Deposit(beneficiary, msg.value, accounts[accountIDs[beneficiary]].capital);
			}



			function withdrawFunds(uint amount) {
				if (accountIDs[msg.sender]<= 0) throw;
				int amountInt = safeUintToInt(amount);
				if (amountInt > safeUintToInt(getFunds(msg.sender)) || amountInt <= 0) throw;
				accounts[accountIDs[msg.sender]].capital = safeSub(accounts[accountIDs[msg.sender]].capital, amount);
				if (!msg.sender.call.value(amount)()) throw;
				Withdraw(msg.sender, amount, accounts[accountIDs[msg.sender]].capital);
			}

			function getFunds(address user) constant returns(uint) {
				if (accountIDs[user]<= 0) return 0;
				return accounts[accountIDs[user]].capital;
			}
		}




