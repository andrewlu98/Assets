    pragma solidity ^0.4.8;

    import "../contracts/OraclizeI.sol";

    contract Master {

    	function addFundsToaddress(address addr) payable {}

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


    contract Bilateral is usingOraclize, SafeMath {
    	//This is a contract between the two people who entered the agreement

    	uint256 public ExpirationTime;
    	uint256 quantity;
    	string public StockSymbol;
    	uint256 public ValueOfContract; //in wei
    	address public MasterAddress = 0x4fa193cd49fce87239a9eae0489d26ca05f2d73d; //This should be the actual address
    	Master masterC = Master(MasterAddress);
    	uint256 StockPriceInCents;
    	uint256 UpperLimit; //in cents
    	uint256 LowerLimit; //in cents
    	address CallOwnerAddress;
    	address PutOwnerAddress;
    	string QueryString;
    	address BilateralAddress;

    	uint256 PayoutCallOwner=0;
    	uint256 PayoutPutOwner=0;
    	bool ParametersSet=false;
    	bool notfinished=true;

    	event Message(address contractaddress, string msg);
    	event PayoutMessage(address contractaddress, address callowner, uint256 callpayout, address putowner, uint256 putpayout);
    	event Price(uint price);



    	modifier OnlyMaster {
    		if (msg.sender == MasterAddress) _;
    	}

    	function() payable { //FallBack deposits money into Master
    		masterC.addFundsToaddress.value(msg.value) (msg.sender);
    	}
    	function Bilateral(){
    		BilateralAddress=this;
    	}

    	function AddBilateral(string symbol, address CallAddr, address PutAddr, uint256 ExpTime, uint Upper, uint Lower) OnlyMaster payable {
    		if (!ParametersSet){
    			CallOwnerAddress = CallAddr;
    			PutOwnerAddress = PutAddr;
    			ExpirationTime = ExpTime;      
    			LowerLimit = Lower; //In USD Cents
    			UpperLimit = Upper; //In USD Cents
    			StockSymbol = symbol;
    			ValueOfContract=this.balance;
    			ParametersSet = true;
    		}
    		else{
    			throw;
    		}

    	}

    	function __callback(bytes32 myid, string result) { //I don't really understand this
    	if (msg.sender != oraclize_cbAddress()) throw;
    	StockPriceInCents = parseInt(result, 2); // let's save it as $ cents
    	Price(StockPriceInCents);
    	}


    function FinishContract() {
    	uint256 currenttime=block.timestamp;         
    	if (notfinished && currenttime > ExpirationTime){
    		//if (true){   
    			QueryString=strConcat("xml(http://www.enclout.com/api/v1/yahoo_finance/show.xml?&auth_token=E6VEUB6zgtv_2LRxiNS5&text=",StockSymbol,").stocks.stock.close");
    			oraclize_query("URL", QueryString);
    			notfinished=false;
    			Payout();
    			PayoutMessage(this, CallOwnerAddress, PayoutCallOwner, PutOwnerAddress, PayoutPutOwner);
    		}
    		else if (notfinished==false){
    			Message(this,'Contract has already finished.');
    		}
    		else if (currenttime>ExpirationTime) {                       
    			//Do some refunds - this should never happen
    			PayoutPutOwner=ValueOfContract/2;
    			PayoutCallOwner=safeSub(ValueOfContract,PayoutPutOwner); //This should be SafeSubb (but I dont want to add the other contract ....)
    			notfinished=false;
    			Payout();
    			PayoutMessage(this, CallOwnerAddress, PayoutCallOwner, PutOwnerAddress, PayoutPutOwner);
    			Message(this,'A serious error occured.');

    		}
    		else {
    			Message(this, 'Not expired yet.');

    		}
    	}

    	function Payout () private returns(bool) {

    		if (StockPriceInCents>UpperLimit){
    			PayoutCallOwner=ValueOfContract;

    		}
    		else if (StockPriceInCents<LowerLimit){
    			PayoutPutOwner=ValueOfContract;

    		}
    		else{ //This randomises rounding errors
    			if (block.timestamp%2==1) {
    			PayoutCallOwner = safeMul(ValueOfContract,safeSub(StockPriceInCents,LowerLimit))/safeSub(UpperLimit,LowerLimit);
    			PayoutPutOwner = safeSub(ValueOfContract,PayoutCallOwner);
    			} else{
    			PayoutPutOwner = safeMul(ValueOfContract,safeSub(UpperLimit,StockPriceInCents))/safeSub(UpperLimit,LowerLimit);
    			PayoutCallOwner = safeSub(ValueOfContract,PayoutPutOwner);
    			}
    		}
    		// Send balance back to master contract
    		masterC.addFundsToaddress.value(PayoutCallOwner) (CallOwnerAddress);
    		masterC.addFundsToaddress.value(PayoutPutOwner) (PutOwnerAddress);
    		return true;

    	}

    }


