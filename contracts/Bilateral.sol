    pragma solidity ^0.4.2;
   
import "../contracts/OraclizeI.sol";
import "../contracts/MasterContract.sol";

    contract Bilateral is usingOraclize {
        //This is a contract between the two people who entered the agreement

        uint256 public ExpirationTime;
        uint256 public quantity;
        string public StockSymbol;
        uint256 public ValueOfContract; //in wei
        address public MasterAddress; //This should be the actual address
        uint256 StockPriceInCents;
        uint256 UpperLimit; //in cents
        uint256 LowerLimit; //in cents
        address CallOwnerAddress;
        address PutOwnerAddress;
        string QueryString;

        uint256 PayoutCallOwner=0;
        uint256 PayoutPutOwner=0;
        bool ParametersSet=false;
        bool notfinished=true;

        event Message(address contractaddress, string msg);
        event PayoutMessage(address contractaddress, address callowner, uint256 callpayout, address putowner, uint256 putpayout);



        modifier OnlyMaster {
           if (msg.sender == MasterAddress) _;
        }

        function() payable {
            ValueOfContract = this.balance;
        }

        function Bilateral(address CallAddr, address PutAddr, uint256 ExpTime, uint256 Upper, uint256 Lower, string Symbol) OnlyMaster payable {
            if (!ParametersSet){
            CallOwnerAddress = CallAddr;
            PutOwnerAddress = PutAddr;
            ExpirationTime = ExpTime;      
            LowerLimit = Lower; //In USD Cents
            UpperLimit = Upper; //In USD Cents
            StockSymbol = Symbol;
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
    }

    function TestFunc(address asdf) {
        Message(asdf, "sasdf");
    }


    function FinishContract() {
            uint256 currenttime=block.timestamp;         
            if (notfinished && currenttime > ExpirationTime){
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
                PayoutCallOwner=ValueOfContract-PayoutPutOwner; //This should be SafeSubb (but I dont want to add the other contract ....)
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
                else{
                   PayoutCallOwner = (ValueOfContract*(StockPriceInCents-LowerLimit))/(UpperLimit-LowerLimit);
                   PayoutPutOwner = ValueOfContract-PayoutCallOwner;
               }
               // Send balance back to master contract
                //MasterAddress.addFundsToaddress.value(PayoutCallOwner) (CallOwnerAddress);
                //MasterAddress.addFundsToaddress.value(PayoutPutOwner) (PutOwnerAddress);
                return true;

        }

    }


