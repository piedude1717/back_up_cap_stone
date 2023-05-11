pragma solidity >=0.7.0 <0.9.0;

contract Lending {
    loan[]  private loans;
    lendee[] private  lendees; 
    lender[] private  lenders; 

    struct lender {
        address payable lenderAddress;
        uint256[] loanIds; 
    }

    struct lendee {
        address payable lendeeAddress;
        uint256[] loanIds; 
    }

    struct loan {
        address payable lendee;
        address payable lender;
        uint256 loanId; 
        uint256  loanAmount;
        uint256  loanAmountLeft;
        uint256  totalReceivedAmount;
        uint256  totalInterest;
        uint256  principleLoanPayed;
        uint256  interestPayed;
        uint256  interestRate;
        uint256  loanPeriod;
        uint256  loanInstallmentPeriod;
        uint256  loanStart;
        uint256  loanEnd;
        bool  loanRepaid;
        bool  interestRepaid;
        uint256  lateFee;
        uint256  gracePeriod;
        uint256  defaultAmount;
        uint256  installmentAmount;
        uint256  previousLoanInstallmentDate; 
        uint256  daysBetweenInstallments;
        uint256  interestLeft;
        }

    uint nextLoanId;
    address public owner;
    bool private lenderDeposit; 
    bool private lenderWithdrawal;
    bool private lendeeDeposit;
    bool private lendeeWithdrawal;

    event LoanCreated(string message, uint loanId, address payable lender, address payable lendee, uint256 loanAmount, uint256 interestRate, uint256 loanPeriod, uint256 loanInstallmentPeriod, uint256 installmentAmount);
    event Lended(address payable lendee, address payable lender, uint256 loanAmount);
    event InstallmentRepaid(address payable lender, address payable lendee, uint256 loanAmountLeft, uint256 totalReceivedAmount, uint256 principleLoanPayed, bool LoanRepaid);
    event LoanLate(address payable lender, address payable lendee);
    event LoanDefaulted(address payable lender, address payable lendee);
    event LoanRepaidInFull(address payable lender, address payable lendee, uint256 interestPayed, uint256 principleLoanPayed);
    event InterestRepaid(address payable lender, address payable lendee, uint256 interestLeft, uint256 InterestRepaid, uint256 totalReceivedAmount);
    event basicString(string basicString);
    event amountLeft(uint loanId, uint amountLeft);
    event myActiveLoans(string message, uint256[] _loanIds, uint256[] loanIds);
    event thisSCAddress(string message, address scAddress);
    event emitUint(uint blank);

    constructor()  {
        owner = msg.sender;
        nextLoanId = 0;
    }

    //unfortunateley there is no real way to do continuous payments based off of time, at least not natively, however I added some code in here that will be used as a pretend
    //monthly payment plan -- loanInstallmentPeriod, loanInstallmentAmount
    //DEPRECATED
    // function addLendeeToLoan(address payable lendeeAddress, uint loanId) public {
    //     require(msg.sender == owner);
    //     loans[loanId].lendees.push(lendeeAddress);
    //     emit basicString("You succesfully added a lendee to the loan!");
    // }
    //DEPRECATED
    // function addLenderToLoan(address payable lenderAddress, uint loanId) public {
    //     require(msg.sender == owner);
    //      loans[loanId].lenders.push(lenderAddress);
    //      emit basicString("You succesfully added a lender to the loan!");
    // }
    
    function getLenderArrayIndex(address payable lenderAddress) private returns (uint){
        for (uint i = 0; i < lenders.length; i++) {
            if(lenders[i].lenderAddress == lenderAddress) {
                emit emitUint(i); 
                return i;
            } 
        }
                return 999999999;
            
    }

    function getLendeeArrayIndex(address payable lendeeAddress) private returns (uint){
        for (uint i = 0; i < lendees.length; i++) {
            if(lendees[i].lendeeAddress == lendeeAddress) {
                emit emitUint(i); 
                return i; 
            } 
        }
        return 999999999;
        
    }

    function checkifLoanExistsInArray(uint loanId) private returns(bool){
        bool returnedTrue = false;
        for (uint i = 0; i < loans.length; i++) {
            if(loans[i].loanId == loanId) {
                return true; 
                returnedTrue = true;
            }
        }
        if (returnedTrue == false) {
            return false;
        }
        
    }

    function addNewLenderToDataBase(address payable lenderAddress) private{
        lender memory newLender;
        newLender.lenderAddress = lenderAddress; 
        lenders.push(newLender);
    }

    function addNewLendeeToDataBase(address payable lendeeAddress) private{
        lendee memory newLendee; 
        newLendee.lendeeAddress = lendeeAddress; 
        lendees.push(newLendee);
    }


    function checkIfLendeeHasAccessToLoan(address payable lendeeAddress, uint loanId) private returns(bool){
        uint lendeeIndex = getLendeeArrayIndex(lendeeAddress);
        bool returnedTrue = false;
        if (lendeeIndex == 999999999) {return false;}
        //require(lendeeIndex != 999999999, "This lendee does not exist!");
        for (uint i = 0; i < lendees[lendeeIndex].loanIds.length; i++) {
            if (loanId == lendees[lendeeIndex].loanIds[i]) {
                return true;
                returnedTrue = true;
            }
        }
        if (returnedTrue == false) {
            return false;
        }
    }

    function checkifLenderHasAccessToLoan(address payable lenderAddress, uint loanId) private returns(bool){
        uint lenderIndex = getLenderArrayIndex(lenderAddress);
        bool returnedTrue = false;
        //require(lenderIndex != 999999999, "This lendee does not exist!");
        if (lenderIndex == 999999999) {return false;}
        for (uint i = 0; i < lenders[lenderIndex].loanIds.length; i++) {
            if (loanId == lenders[lenderIndex].loanIds[i]) {
                return true;
                returnedTrue = true;
            }
        }
        if (returnedTrue == false) {
            return false;
        }
    
    }

    //change loan period 
    //loanInstallment period must be less than loan period 
    
    function createLoan(address payable _lendee, address payable _lender, uint256 _loanAmount, uint256 _interestRate, uint256 _loanPeriod, uint256 _loanInstallmentPeriod) public {
        require(msg.sender == _lender);
        require(_loanAmount > 0);
        require(_interestRate > 0 && _interestRate <= 100);
        require(_loanPeriod > 0);
        loan memory newLoan;
        newLoan.loanId = nextLoanId; 
        nextLoanId += 1;
        newLoan.lender = _lendee;
        newLoan.lender = _lender;
        newLoan.loanAmount = _loanAmount;
        newLoan.interestRate = _interestRate;
        newLoan.loanPeriod = _loanPeriod;
        newLoan.loanInstallmentPeriod = _loanInstallmentPeriod;
        newLoan.daysBetweenInstallments = _loanInstallmentPeriod;
        newLoan.installmentAmount = _loanAmount/_loanInstallmentPeriod;
        newLoan.loanStart = block.timestamp;
        newLoan.loanEnd = block.timestamp + _loanPeriod;
        newLoan.totalInterest = _loanAmount*_interestRate/100;
        newLoan.interestLeft = newLoan.totalInterest;
        newLoan.loanAmountLeft = _loanAmount;
        newLoan.totalReceivedAmount = 0;
        newLoan.principleLoanPayed = 0;
        newLoan.interestPayed = 0;
        newLoan.previousLoanInstallmentDate = block.timestamp;
        loans.push(newLoan);
        lenderDeposit = true;
        uint lenderArrayIndex = getLenderArrayIndex(_lender);

        if (lenderArrayIndex != 999999999) {
            lenders[lenderArrayIndex].loanIds.push(newLoan.loanId);
        } else {
            addNewLenderToDataBase(_lender);
            lenders[getLenderArrayIndex(_lender)].loanIds.push(newLoan.loanId);
        }
        uint lendeeArrayIndex = getLendeeArrayIndex(_lendee);
        if (lendeeArrayIndex != 999999999) {
            lendees[lendeeArrayIndex].loanIds.push(newLoan.loanId);
        } else {
            addNewLendeeToDataBase(_lendee);
            lendees[getLendeeArrayIndex(_lendee)].loanIds.push(newLoan.loanId);
        }
        emit LoanCreated("Please write down your loanId so you can access it at a later date.", newLoan.loanId, newLoan.lender, newLoan.lendee, newLoan.loanAmount, newLoan.interestRate, newLoan.loanPeriod, newLoan.loanInstallmentPeriod, newLoan.installmentAmount);
    }

    function deposit(address walletAddress) payable public {}



    function lendLoan(uint256 loanId) public payable {
        require(msg.sender == loans[loanId].lender);
        require(msg.value >= loans[loanId].loanAmount);
        require(lenderDeposit == true);
        this.deposit(address(this));
        //require(msg.value == loans[loanId].loanAmount);
        loans[loanId].lendee.transfer(loans[loanId].loanAmount);
        emit Lended(loans[loanId].lendee, loans[loanId].lender, loans[loanId].loanAmount);
        }
    

    function repayInstallment(uint loanId) public payable {
        bool lendeeHasAccess = checkIfLendeeHasAccessToLoan(payable(msg.sender), loanId);
        require(lendeeHasAccess == true);
        require(msg.value >= loans[loanId].installmentAmount);
        uint256 currTimeBwInstallments = block.timestamp - loans[loanId].previousLoanInstallmentDate; 
        if (currTimeBwInstallments * 1 days > loans[loanId].daysBetweenInstallments ) {
            this.deposit(address(this));
            require(msg.value >= loans[loanId].installmentAmount + loans[loanId].lateFee);
            loans[loanId].lender.transfer(loans[loanId].installmentAmount + loans[loanId].lateFee);
            loans[loanId].loanAmountLeft = loans[loanId].loanAmountLeft - msg.value;
            loans[loanId].totalReceivedAmount += msg.value  + loans[loanId].lateFee; 
            loans[loanId].principleLoanPayed += msg.value;
            loans[loanId].previousLoanInstallmentDate = block.timestamp;
            emit LoanLate(loans[loanId].lender, loans[loanId].lendee);
        } else if (currTimeBwInstallments * 1 days - loans[loanId].daysBetweenInstallments  > loans[loanId].daysBetweenInstallments || block.timestamp > loans[loanId].loanEnd) {
            emit LoanDefaulted(loans[loanId].lender, loans[loanId].lendee);
            this.defaultLoan(loanId);
        } else {
            this.deposit(address(this));
            loans[loanId].lender.transfer(loans[loanId].installmentAmount);
        }
        if (loans[loanId].loanAmountLeft == 0 || loans[loanId].interestLeft == 0) {
            loans[loanId].loanRepaid = true;
            emit LoanRepaidInFull(loans[loanId].lender, loans[loanId].lendee, loans[loanId].interestPayed, loans[loanId].principleLoanPayed);
        }
        emit InstallmentRepaid(loans[loanId].lender, loans[loanId].lendee, loans[loanId].loanAmountLeft, loans[loanId].totalReceivedAmount, loans[loanId].principleLoanPayed, loans[loanId].loanRepaid);
        
    }

    function repayInterest(uint loanId) public payable {
        bool lendeeHasAccess = checkIfLendeeHasAccessToLoan(payable(msg.sender), loanId);
        require(lendeeHasAccess == true);
        require(msg.value >= 0);
        if (block.timestamp > loans[loanId].loanEnd) {
            this.defaultLoan(loanId);
            emit LoanDefaulted(loans[loanId].lender, loans[loanId].lendee);
        } else if (msg.value <= loans[loanId].interestLeft) {
            this.deposit(address(this));
            loans[loanId].lender.transfer(msg.value);
            loans[loanId].interestPayed += msg.value; 
            loans[loanId].interestLeft -= msg.value;
            loans[loanId].totalReceivedAmount += msg.value;
        } 
        if (loans[loanId].loanAmountLeft == 0 || loans[loanId].interestLeft == 0) {
            loans[loanId].loanRepaid = true;
            emit LoanRepaidInFull(loans[loanId].lender, loans[loanId].lendee, loans[loanId].interestPayed, loans[loanId].principleLoanPayed);
        }
        emit InterestRepaid(loans[loanId].lender, loans[loanId].lendee, loans[loanId].interestLeft, loans[loanId].interestPayed, loans[loanId].totalReceivedAmount);
        
    }

    function balanceOf() public view returns(uint) {
        require(msg.sender == owner);
        return address(this).balance;
    }

    
    function remainingLoanBalance(uint loanId) public {
        bool lendeeAccess = checkIfLendeeHasAccessToLoan(payable(msg.sender),  loanId);
        bool lenderAccess =  checkifLenderHasAccessToLoan(payable(msg.sender),  loanId);
        require(lendeeAccess == true || lenderAccess == true, "You do not have access to this loan.");
        emit amountLeft(loanId, loans[loanId].loanAmountLeft);
        //return loans[loanId].loanAmountLeft;
    }

        
    function remainingInterestBalance(uint loanId) public {
        bool lendeeAccess = checkIfLendeeHasAccessToLoan(payable(msg.sender),  loanId);
        bool lenderAccess =  checkifLenderHasAccessToLoan(payable(msg.sender),  loanId);
        require(lendeeAccess == true || lenderAccess == true, "You do not have access to this loan.");
        emit amountLeft(loanId, loans[loanId].interestLeft);
        //return loans[loanId].interestLeft;
    }

    
    function remainingTimeForCurrentInstallment(uint loanId) private {
        bool lendeeAccess = checkIfLendeeHasAccessToLoan(payable(msg.sender),  loanId);
        bool lenderAccess =  checkifLenderHasAccessToLoan(payable(msg.sender),  loanId);
        require(lendeeAccess == true || lenderAccess == true, "You do not have access to this loan.");
        emit amountLeft(loanId, (loans[loanId].daysBetweenInstallments - ((block.timestamp - loans[loanId].previousLoanInstallmentDate) * 1 days)));
        //return loans[loanId].daysBetweenInstallments - ((block.timestamp - loans[loanId].previousLoanInstallmentDate) * 1 days);
    }

    function remainingTimeForLoan(uint loanId) public {
        bool lendeeAccess = checkIfLendeeHasAccessToLoan(payable(msg.sender),  loanId);
        bool lenderAccess =  checkifLenderHasAccessToLoan(payable(msg.sender),  loanId);
        require(lendeeAccess == true || lenderAccess == true, "You do not have access to this loan.");
        emit amountLeft(loanId, (loans[loanId].loanEnd - block.timestamp));
        //return (loans[loanId].loanEnd - block.timestamp) * 1 days;
    }

    
    function checkPaidBalance(uint loanId) public returns(uint) {
        bool lendeeAccess = checkIfLendeeHasAccessToLoan(payable(msg.sender),  loanId);
        bool lenderAccess =  checkifLenderHasAccessToLoan(payable(msg.sender),  loanId);
        require(lendeeAccess == true || lenderAccess == true, "You do not have access to this loan.");
        return loans[loanId].totalReceivedAmount;
    }


    function repayCustAmountLoan(uint loanId) public payable {
        bool lendeeAccess = checkIfLendeeHasAccessToLoan(payable(msg.sender),  loanId);
        require(lendeeAccess == true, "You do not have access to this loan.");
        require(msg.value >= 0);
        loans[loanId].loanAmountLeft = loans[loanId].loanAmountLeft - msg.value;
        loans[loanId].totalReceivedAmount += msg.value  + loans[loanId].lateFee; 
        loans[loanId].principleLoanPayed += msg.value;
        this.deposit(address(this));
        loans[loanId].lender.transfer(msg.value);
        }
        
    function defaultLoan(uint loanId) public {
        require(!loans[loanId].loanRepaid);
        emit LoanDefaulted(loans[loanId].lender, loans[loanId].lendee);
    }

    // loan[]  private loans;
    // lendee[] private  lendees; 
    // lender[] private  lenders; 
    function getMyActiveLoans() public {
        uint[] memory fakeLoans;
        uint posLenderIndex = getLenderArrayIndex(payable(msg.sender));
        uint posLendeeIndex = getLendeeArrayIndex(payable(msg.sender));
        require(posLenderIndex != 999999999 || posLendeeIndex != 999999999, "This address is neither connected to a lender or lendee in our database; make sure you are using the correct wallet.");
        if (posLendeeIndex == 999999999) {
            emit myActiveLoans("You are a lender, here are your loanIds", lenders[posLenderIndex].loanIds, fakeLoans);
        } else if (posLenderIndex == 999999999) {
            emit myActiveLoans("You are a lendee, here are your loanIds", lendees[posLendeeIndex].loanIds, fakeLoans);

        } else {
            emit myActiveLoans("You are both a lendee and lender, here are your loanIds (The first series of Ids is for you lendee persona, the second is for your lender persona). ", lendees[posLendeeIndex].loanIds, lenders[posLenderIndex].loanIds);
        }
    }

    function getThisSmartContractAddress() public {
        emit thisSCAddress("Here is the address of this smart contract", address(this));
    }
}