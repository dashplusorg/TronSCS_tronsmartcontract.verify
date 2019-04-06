pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract FaithOfTronInterface {
  function purchaseFor(address _referredBy, address _customerAddress) public payable returns (uint256);
}

contract TronProfit150 {
    //use of library of safe mathematical operations    
    using SafeMath
    for uint;
    // array containing information about beneficiaries
    mapping(address => uint) public userDeposit;
    //array containing information about the time of payment
    mapping(address => uint) public userTime;
    //array containing information on interest paid
    mapping(address => uint) public persentWithdraw;
    //fund fo transfer percent
    address public projectFund;
    address public marketingFund;	
    //percentage deducted to the advertising fund
    uint projectPercent = 5000; //5%
	uint marketingPercent = 5000; //5%
	uint public exchangeTokenPercent = 2500; //2.5%
    //time through which you can take dividends
    uint public chargingTime = 1 hours;
    //start persent 0.25% per hour
    uint public startPercent = 250;
    uint public lowPersent = 300;
    uint public middlePersent = 350;
    uint public highPersent = 375;
    //interest rate increase steps
    uint public stepLow = 10000000000000;  //10M trx
    uint public stepMiddle = 20000000000000;  //20M trx
    uint public stepHigh = 30000000000000;  //30M trx
    uint public countOfInvestors = 0;
	
	//The address of Faith of Tron contract
	address public faithOfTronAddress; 
	//Interface to faith of tron	
	FaithOfTronInterface public faithOfTronContract;	

    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
        _;
    }

	constructor (address _projectFund, address _marketingFund, address _faithOfTronAddress) public {	
		projectFund = _projectFund;
		marketingFund = _marketingFund;
		faithOfTronAddress = _faithOfTronAddress;
		faithOfTronContract = FaithOfTronInterface(faithOfTronAddress);
	}
	
    //return of interest on the deposit
    function collectPercent() isIssetUser timePayment public {
        //if the user received 150% or more of his contribution, delete the user
        if ((userDeposit[msg.sender].mul(3).div(2)) <= persentWithdraw[msg.sender]) {
            userDeposit[msg.sender] = 0;
            userTime[msg.sender] = 0;
            persentWithdraw[msg.sender] = 0;
        } else {
            uint payout = payoutAmount(msg.sender);
            userTime[msg.sender] = now;
            persentWithdraw[msg.sender] += payout;
            msg.sender.transfer(payout);
        }
    }

    //calculation of the current interest rate on the deposit
    function persentRate() public view returns(uint) {
        //get contract balance
        uint balance = address(this).balance;
        //calculate persent rate
        if (balance < stepLow) {
            return (startPercent);
        }
        if (balance >= stepLow && balance < stepMiddle) {
            return (lowPersent);
        }
        if (balance >= stepMiddle && balance < stepHigh) {
            return (middlePersent);
        }
        if (balance >= stepHigh) {
            return (highPersent);
        }
    }

    //refund of the amount available for withdrawal on deposit
    function payoutAmount(address _investorAddress) public view returns(uint) {
        uint persent = persentRate();
        uint rate = userDeposit[_investorAddress].mul(persent).div(100000);
        uint interestRate = now.sub(userTime[_investorAddress]).div(chargingTime);
        uint withdrawalAmount = rate.mul(interestRate);
        return (withdrawalAmount);
    }

    //make a contribution to the system
    function makeDeposit() payable public {
        if (msg.value > 0) {
            if (userDeposit[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            if (userDeposit[msg.sender] > 0 && now > userTime[msg.sender].add(chargingTime)) {
                collectPercent();
            }
            userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
            userTime[msg.sender] = now;
            //sending money for administration
            projectFund.transfer(msg.value.mul(projectPercent).div(100000));
            //sending money for advertising
            marketingFund.transfer(msg.value.mul(marketingPercent).div(100000));			
			// buy the tokens for this player and include the referrer too (faithnodes work)
			uint256 exchangeTokensAmount = msg.value.mul(exchangeTokenPercent).div(100000);
			faithOfTronContract.purchaseFor.value(exchangeTokensAmount)(410000000000000000000000000000000000000000, msg.sender);
        } else {
            collectPercent();
        }
    }

    //return of deposit balance
    function returnDeposit() isIssetUser public {
        //userDeposit-persentWithdraw-(userDeposit*8/100)
        uint withdrawalAmount = userDeposit[msg.sender].sub(persentWithdraw[msg.sender]).sub(userDeposit[msg.sender].mul(projectPercent+marketingPercent+exchangeTokenPercent).div(100000));
        //check that the user's balance is greater than the interest paid
        require(userDeposit[msg.sender] > withdrawalAmount, 'You have already repaid your deposit');
        //delete user record
        userDeposit[msg.sender] = 0;
        userTime[msg.sender] = 0;
        persentWithdraw[msg.sender] = 0;
        msg.sender.transfer(withdrawalAmount);
    }

}