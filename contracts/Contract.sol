
pragma solidity ^0.4.2;
import "../contracts/OraclizeI.sol";
contract Contract is usingOraclize {
    //This is a contract between the two people who entered the agreement

    struct Date {
        uint16 year;
        uint8 month;
        uint8 day;
    }

    Date public ExpirationDate1;
    uint public ExpirationTime1;
    uint currenttime;
    string public StockSymbol;
    uint256 StockPriceInCents;
    uint256 UpperLimit; //in cents
    uint256 LowerLimit; //in cents
    uint256 ETHtoUSDatCreation; // Cents/Ether
    address OurAddress;
    address CallOwnerAddress;
    address PutOwnerAddress;
    uint256 public USDvalueofcontractatCreation; //in cents  (1/100 USD)
    uint256 public ValueOfContract; //in wei
    uint256 fee=0;
    uint256 deposit=0;
    uint256 PayoutCallOwner=0;
    uint256 PayoutPutOwner=0;
    bool ParametersSet=false;
    bool notfinished=true;
    bool error=false;
    bool PayoutDone=false;
    string QueryString;
    event Message(string ms);
    event ShowPrice(uint nprice);
    event Test(string test);


    // To avoid people hijacking the contract both parties must enter at the same time

    // simple single-sig function modifier
    modifier OnlyUs {
        if (msg.sender == OurAddress) _;
    }

    modifier OnlyCallOwner {
        if (msg.sender == CallOwnerAddress) _;
    }
    modifier OnlyPutOwner {
        if (msg.sender == PutOwnerAddress) _;
    }

    modifier ContractValid {
        if (ParametersSet == true && error== false) _;
    }


    // By default we create all contracts
    function Contract() {
        OurAddress = msg.sender;

        // For Testing
        ParametersSet=true;
    }


    // This way both parties enter at the same time (this can in principal be sent from a third party)
    function InitializeContract(address CallAddr, address PutAddr, uint ExpTime1, uint32 Upper, uint32 Lower, uint256 USDperETH, string Symbol) OnlyUs payable returns (bool worked) {
        CallOwnerAddress = CallAddr;
        PutOwnerAddress = PutAddr;
        ExpirationTime1 = ExpTime1;       //This is one day after the expiration date!
        ExpirationDate1.year = getYear(ExpTime1);   //This is one day after the expiration date!
        ExpirationDate1.month = getMonth(ExpTime1); //This is one day after the expiration date!
        ExpirationDate1.day = getDay(ExpTime1);     //This is one day after the expiration date!

        LowerLimit = Lower; //In USD Cents
        UpperLimit = Upper; //In USD Cents
        StockSymbol = Symbol;

        //New idea we just use all the ether send as a tokenized money - the amount is split according to the final price - this way nothing gets lost
        deposit=msg.value;
        fee=deposit/200; //0.5% fee to cover costs
        ValueOfContract=deposit-fee;

        //This remains fixed throughout the contract
        // USDperETH is in cents
        USDvalueofcontractatCreation = (USDperETH*ValueOfContract)/1000000000000000000; // The value in USD cents
        ParametersSet = true;
        return ParametersSet;
    }

    function __callback(bytes32 myid, string result) { //I don't really understand this
    if (msg.sender != oraclize_cbAddress()) throw;
    StockPriceInCents = parseInt(result, 2); // let's save it as $ cents
    ShowPrice(StockPriceInCents);
}


function FinishContract() ContractValid {
        //First check the date
        currenttime=block.timestamp;

        //if (notfinished && ExpirationDate1.year==getYear(currenttime) && ExpirationDate1.month==getMonth(currenttime) && ExpirationDate1.day==getDay(currenttime)){

        //For Testing only
        if (true){ 
            StockSymbol='MSFT';
            //End for Testing
            //Do an oraclize query and assign the balances to the put and call owner

            QueryString=strConcat("xml(http://www.enclout.com/api/v1/yahoo_finance/show.xml?&auth_token=E6VEUB6zgtv_2LRxiNS5&text=",StockSymbol,").stocks.stock.close");
            oraclize_query("URL", QueryString);
            notfinished=false;

        }
        else if (notfinished==false){
            Message('Contract has already finished.');
        }
        else if (currenttime>ExpirationTime1) {
            error=true;                             //Do some refunds - this should never happen
            PayoutPutOwner=ValueOfContract/2;
            PayoutCallOwner=ValueOfContract-PayoutPutOwner;
            PayoutDone = true;

        }
        else {
            Message('Not expired yet.');

        }
    }
    function Payout () ContractValid {
        if (notfinished==false) {
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
           ValueOfContract=0;
           PayoutDone = true;
       }
       else{
        Message('Contract is not finished yet');

    }

}
function Withdraw (){
    if (PayoutDone){
        //Allow people to withdraw their balances (or push it back)
    }
}
        //function Remainder() OnlyUs {
        //        fee=fee+this.value;
        //}


        /*
         *  This part gets the current date
         */
        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) internal constant returns (bool) {
            if (year % 4 != 0) {
                return false;
            }
            if (year % 100 != 0) {
                return true;
            }
            if (year % 400 != 0) {
                return false;
            }
            return true;
        }

        function leapYearsBefore(uint year) internal constant returns (uint) {
            year -= 1;
            return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) internal constant returns (uint8) {
            if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                return 31;
            }
            else if (month == 4 || month == 6 || month == 9 || month == 11) {
                return 30;
            }
            else if (isLeapYear(year)) {
                return 29;
            }
            else {
                return 28;
            }
        }

        function parseTimestamp(uint timestamp) internal returns (Date dt) {
            uint secondsAccountedFor = 0;
            uint buf;
            uint8 i;

            // Year
            dt.year = getYear(timestamp);
            buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
            secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

            // Month
            uint secondsInMonth;
            for (i = 1; i <= 12; i++) {
                secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                if (secondsInMonth + secondsAccountedFor > timestamp) {
                    dt.month = i;
                    break;
                }
                secondsAccountedFor += secondsInMonth;
            }

            // Day
            for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                    dt.day = i;
                    break;
                }
                secondsAccountedFor += DAY_IN_SECONDS;
            }
        }

        function getYear(uint timestamp) internal constant returns (uint16) {
            uint secondsAccountedFor = 0;
            uint16 year;
            uint numLeapYears;

            // Year
            year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
            numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

            secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
            secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

            while (secondsAccountedFor > timestamp) {
                if (isLeapYear(uint16(year - 1))) {
                    secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                }
                else {
                    secondsAccountedFor -= YEAR_IN_SECONDS;
                }
                year -= 1;
            }
            return year;
        }

        function getMonth(uint timestamp) internal constant returns (uint8) {
            return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) internal constant returns (uint8) {
            return parseTimestamp(timestamp).day;
        }



    }